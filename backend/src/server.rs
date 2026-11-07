use std::pin::Pin;
use std::sync::atomic::{AtomicI32, AtomicI64, AtomicU32, AtomicU64, Ordering};
use std::sync::Arc;
use std::time::{Instant, SystemTime, UNIX_EPOCH};

use colored::Colorize;
use tokio::sync::{broadcast, Mutex, RwLock};
use tokio_stream::{wrappers::BroadcastStream, Stream, StreamExt};
use tonic::{Request, Response, Status};

use crate::dsp::{adc_to_mv, EcgDspPipeline, SAMPLE_RATE_HZ};
use crate::proto::telemetry_service_server::TelemetryService;
use crate::proto::{
    CardiacEvent, CardiacEventType, CardiacMetrics, ConfigureSourceRequest, EcgSample,
    EcgWaveformChunk, GetStatusRequest, LogEntry, LogLevel, SourceMode, StatusResponse,
    StreamEcgRequest, StreamEventsRequest, StreamLogsRequest,
};
use crate::simulator::EcgSimulator;

pub fn now_millis() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64
}

#[derive(Debug)]
pub struct SharedState {
    pub ecg_tx: broadcast::Sender<EcgWaveformChunk>,
    pub event_tx: broadcast::Sender<CardiacEvent>,
    pub log_tx: broadcast::Sender<LogEntry>,
    pub seq_counter: AtomicI64,
    pub event_seq_counter: AtomicI64,
    pub total_samples: AtomicU64,
    pub source_mode: AtomicI32,
    pub target_sim_bpm: AtomicU32,
    pub start_time: Instant,
    pub dsp_pipeline: Arc<Mutex<EcgDspPipeline>>,
    pub simulator: Arc<Mutex<EcgSimulator>>,
    pub latest_metrics: Arc<RwLock<CardiacMetrics>>,
    pub last_lead_off: Arc<Mutex<bool>>,
}

impl Default for SharedState {
    fn default() -> Self {
        Self::new()
    }
}

impl SharedState {
    pub fn new() -> Self {
        let (ecg_tx, _) = broadcast::channel(128);
        let (event_tx, _) = broadcast::channel(128);
        let (log_tx, _) = broadcast::channel(256);

        let initial_metrics = EcgDspPipeline::new().compute_metrics(false, false);

        Self {
            ecg_tx,
            event_tx,
            log_tx,
            seq_counter: AtomicI64::new(1),
            event_seq_counter: AtomicI64::new(1),
            total_samples: AtomicU64::new(0),
            source_mode: AtomicI32::new(SourceMode::Simulator as i32),
            target_sim_bpm: AtomicU32::new(72),
            start_time: Instant::now(),
            dsp_pipeline: Arc::new(Mutex::new(EcgDspPipeline::new())),
            simulator: Arc::new(Mutex::new(EcgSimulator::new(72))),
            latest_metrics: Arc::new(RwLock::new(initial_metrics)),
            last_lead_off: Arc::new(Mutex::new(false)),
        }
    }

    pub fn get_source_mode(&self) -> SourceMode {
        SourceMode::try_from(self.source_mode.load(Ordering::Relaxed))
            .unwrap_or(SourceMode::Simulator)
    }

    pub fn set_source_mode(&self, mode: SourceMode) {
        self.source_mode.store(mode as i32, Ordering::SeqCst);
        self.record_cardiac_event(
            CardiacEventType::SourceModeSwitched,
            0,
            0,
            format!("Data ingestion source switched to {:?}", mode),
        );
    }

    pub fn log(&self, level: LogLevel, component: &str, message: impl Into<String>) {
        let entry = LogEntry {
            timestamp_unix_millis: now_millis(),
            level: level.into(),
            component: component.to_string(),
            message: message.into(),
        };

        let level_str = match level {
            LogLevel::Debug => "[DEBUG]".cyan(),
            LogLevel::Info => "[INFO ]".green(),
            LogLevel::Warn => "[WARN ]".yellow(),
            LogLevel::Error => "[ERROR]".red().bold(),
        };
        println!("{} [{}] {}", level_str, entry.component.magenta(), entry.message);

        let _ = self.log_tx.send(entry);
    }

    pub fn record_cardiac_event(
        &self,
        event_type: CardiacEventType,
        bpm: u32,
        rr_interval_ms: u32,
        description: impl Into<String>,
    ) -> CardiacEvent {
        let seq = self.event_seq_counter.fetch_add(1, Ordering::SeqCst);
        let event = CardiacEvent {
            sequence_number: seq,
            timestamp_unix_millis: now_millis(),
            event_type: event_type as i32,
            bpm,
            rr_interval_ms,
            description: description.into(),
        };

        let _ = self.event_tx.send(event.clone());
        event
    }

    /// Ingests a raw batch of (ADC, LO+, LO-) samples, runs real-time DSP, computes metrics,
    /// triggers alarms/events, and broadcasts the chunk to gRPC subscribers.
    pub fn ingest_raw_batch(&self, raw_samples: Vec<(u32, bool, bool)>, source: SourceMode) {
        if raw_samples.is_empty() {
            return;
        }

        let now = now_millis();
        let mut dsp = match self.dsp_pipeline.try_lock() {
            Ok(guard) => guard,
            Err(_) => return, // Drop frame if busy to maintain hard real-time latency
        };

        let mut ecg_samples = Vec::with_capacity(raw_samples.len());
        let mut has_r_peak_in_batch = false;
        let mut last_lo_p = false;
        let mut last_lo_n = false;

        for (adc, lo_p, lo_n) in raw_samples {
            self.total_samples.fetch_add(1, Ordering::Relaxed);
            let lead_off = lo_p || lo_n;
            last_lo_p = lo_p;
            last_lo_n = lo_n;

            let (filtered_mv, is_r_peak) = dsp.process_sample(adc, now, lead_off);
            let raw_mv = adc_to_mv(adc);

            if is_r_peak {
                has_r_peak_in_batch = true;
            }

            ecg_samples.push(EcgSample {
                timestamp_unix_millis: now,
                raw_adc: adc,
                voltage_mv: (raw_mv * 1000.0).round() / 1000.0,
                filtered_mv: (filtered_mv * 1000.0).round() / 1000.0,
                is_r_peak,
                lead_off,
            });
        }

        let metrics = dsp.compute_metrics(last_lo_p, last_lo_n);
        drop(dsp);

        // Update cached metrics
        if let Ok(mut lock) = self.latest_metrics.try_write() {
            *lock = metrics;
        }

        // Check for Lead-Off transition events
        let current_lo = last_lo_p || last_lo_n;
        if let Ok(mut last_lo) = self.last_lead_off.try_lock() {
            if current_lo != *last_lo {
                *last_lo = current_lo;
                if current_lo {
                    self.record_cardiac_event(
                        CardiacEventType::LeadOffTriggered,
                        metrics.heart_rate_bpm,
                        metrics.rr_interval_ms,
                        "Lead-Off detected on AD8232! Check electrode placement.",
                    );
                } else {
                    self.record_cardiac_event(
                        CardiacEventType::LeadReconnected,
                        metrics.heart_rate_bpm,
                        metrics.rr_interval_ms,
                        "Leads re-connected. ECG signal restored.",
                    );
                }
            }
        }

        // Trigger discrete R-peak event
        if has_r_peak_in_batch && !current_lo {
            self.record_cardiac_event(
                CardiacEventType::RPeakDetected,
                metrics.heart_rate_bpm,
                metrics.rr_interval_ms,
                format!("QRS R-Peak detected: {} BPM (RR: {} ms)", metrics.heart_rate_bpm, metrics.rr_interval_ms),
            );
        }

        // Broadcast ECG waveform chunk to all active gRPC clients
        let seq = self.seq_counter.fetch_add(1, Ordering::SeqCst);
        let chunk = EcgWaveformChunk {
            sequence_number: seq,
            sample_rate_hz: SAMPLE_RATE_HZ as u32,
            samples: ecg_samples,
            metrics: Some(metrics),
            source_mode: source as i32,
        };

        let _ = self.ecg_tx.send(chunk);
    }
}

#[derive(Clone)]
pub struct TelemetryServiceImpl {
    pub state: Arc<SharedState>,
}

impl TelemetryServiceImpl {
    pub fn new(state: Arc<SharedState>) -> Self {
        Self { state }
    }
}

#[tonic::async_trait]
impl TelemetryService for TelemetryServiceImpl {
    type StreamEcgStream = Pin<Box<dyn Stream<Item = Result<EcgWaveformChunk, Status>> + Send + 'static>>;
    type StreamCardiacEventsStream = Pin<Box<dyn Stream<Item = Result<CardiacEvent, Status>> + Send + 'static>>;
    type StreamLogsStream = Pin<Box<dyn Stream<Item = Result<LogEntry, Status>> + Send + 'static>>;

    async fn stream_ecg(
        &self,
        request: Request<StreamEcgRequest>,
    ) -> Result<Response<Self::StreamEcgStream>, Status> {
        let req = request.into_inner();
        let client_id = if req.client_id.is_empty() {
            "flutter-client".to_string()
        } else {
            req.client_id
        };

        self.state.log(
            LogLevel::Info,
            "grpc",
            format!("Client '{}' subscribed to real-time ECG waveform stream", client_id),
        );

        let rx = self.state.ecg_tx.subscribe();
        let stream = BroadcastStream::new(rx).filter_map(|res| match res {
            Ok(chunk) => Some(Ok(chunk)),
            Err(_) => None,
        });

        Ok(Response::new(Box::pin(stream)))
    }

    async fn stream_cardiac_events(
        &self,
        request: Request<StreamEventsRequest>,
    ) -> Result<Response<Self::StreamCardiacEventsStream>, Status> {
        let req = request.into_inner();
        let client_id = if req.client_id.is_empty() {
            "flutter-client".to_string()
        } else {
            req.client_id
        };

        self.state.log(
            LogLevel::Info,
            "grpc",
            format!("Client '{}' subscribed to discrete cardiac events", client_id),
        );

        let rx = self.state.event_tx.subscribe();
        let stream = BroadcastStream::new(rx).filter_map(|res| match res {
            Ok(event) => Some(Ok(event)),
            Err(_) => None,
        });

        Ok(Response::new(Box::pin(stream)))
    }

    async fn stream_logs(
        &self,
        request: Request<StreamLogsRequest>,
    ) -> Result<Response<Self::StreamLogsStream>, Status> {
        let req = request.into_inner();
        let client_id = if req.client_id.is_empty() {
            "anonymous".to_string()
        } else {
            req.client_id
        };
        let min_level = req.min_level;

        self.state.log(
            LogLevel::Info,
            "grpc",
            format!("Client '{}' subscribed to log stream (min_level: {:?})", client_id, min_level),
        );

        let rx = self.state.log_tx.subscribe();
        let stream = BroadcastStream::new(rx).filter_map(move |res| match res {
            Ok(entry) if entry.level >= min_level => Some(Ok(entry)),
            Ok(_) => None,
            Err(_) => None,
        });

        Ok(Response::new(Box::pin(stream)))
    }

    async fn get_status(
        &self,
        _request: Request<GetStatusRequest>,
    ) -> Result<Response<StatusResponse>, Status> {
        let uptime = self.state.start_time.elapsed().as_secs();
        let metrics = *self.state.latest_metrics.read().await;
        let total = self.state.total_samples.load(Ordering::Relaxed);
        let mode = self.state.get_source_mode();
        let sim_bpm = self.state.target_sim_bpm.load(Ordering::Relaxed);

        let res = StatusResponse {
            timestamp_unix_millis: now_millis(),
            uptime_seconds: uptime,
            source_mode: mode as i32,
            metrics: Some(metrics),
            total_samples_processed: total,
            target_sim_bpm: sim_bpm,
        };

        Ok(Response::new(res))
    }

    async fn configure_source(
        &self,
        request: Request<ConfigureSourceRequest>,
    ) -> Result<Response<StatusResponse>, Status> {
        let req = request.into_inner();
        let requested_mode = SourceMode::try_from(req.source_mode).unwrap_or(SourceMode::Simulator);

        if req.source_mode != SourceMode::Unspecified as i32 {
            self.state.set_source_mode(requested_mode);
        }

        if req.target_sim_bpm >= 40 && req.target_sim_bpm <= 180 {
            self.state.target_sim_bpm.store(req.target_sim_bpm, Ordering::SeqCst);
            let mut sim = self.state.simulator.lock().await;
            sim.set_target_bpm(req.target_sim_bpm);
        }

        if req.reset_dsp {
            let mut dsp = self.state.dsp_pipeline.lock().await;
            dsp.reset();
        }

        self.get_status(Request::new(GetStatusRequest {})).await
    }
}
