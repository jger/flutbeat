use std::time::Duration;
use clap::Parser;
use colored::Colorize;
use tokio::time::sleep;

use flutbeat_backend::format_timestamp;
use flutbeat_backend::proto::telemetry_service_client::TelemetryServiceClient;
use flutbeat_backend::proto::{
    CardiacEvent, CardiacEventType, EcgWaveformChunk, GetStatusRequest, LogEntry, LogLevel,
    SourceMode, StreamEcgRequest, StreamEventsRequest, StreamLogsRequest,
};

#[derive(Parser, Debug)]
#[command(name = "ecg_receiver")]
#[command(about = "Receives and visualizes real-time ECG telemetry & diagnostics from FlutBeat node")]
struct Args {
    /// Server gRPC URL endpoint
    #[arg(short, long, default_value = "http://127.0.0.1:50051")]
    server_url: String,

    /// Minimum log level to receive (debug, info, warn, error)
    #[arg(short, long, default_value = "info")]
    min_level: String,

    /// Unique client identifier
    #[arg(short, long, default_value = "ecg-receiver-cli")]
    client_id: String,
}

fn parse_log_level(level_str: &str) -> LogLevel {
    match level_str.to_lowercase().as_str() {
        "debug" => LogLevel::Debug,
        "info" => LogLevel::Info,
        "warn" | "warning" => LogLevel::Warn,
        "error" => LogLevel::Error,
        _ => LogLevel::Info,
    }
}

fn render_sparkline(val_mv: f32) -> &'static str {
    // Physiological ECG mV typically spans -0.5 mV to +1.5 mV
    if val_mv < -0.3 {
        " "
    } else if val_mv < -0.1 {
        "▂"
    } else if val_mv < 0.1 {
        "▃"
    } else if val_mv < 0.3 {
        "▄"
    } else if val_mv < 0.6 {
        "▅"
    } else if val_mv < 0.9 {
        "▆"
    } else if val_mv < 1.2 {
        "▇"
    } else {
        "█"
    }
}

fn display_ecg_chunk(chunk: EcgWaveformChunk) {
    if let Some(metrics) = chunk.metrics {
        let mut spark = String::with_capacity(chunk.samples.len());
        let mut had_r_peak = false;

        for s in &chunk.samples {
            spark.push_str(render_sparkline(s.filtered_mv));
            if s.is_r_peak {
                had_r_peak = true;
            }
        }

        let heart_icon = if had_r_peak {
            "❤️  BEEP".bright_red().bold()
        } else {
            "🤍      ".dimmed()
        };

        let mode_str = match SourceMode::try_from(chunk.source_mode).unwrap_or(SourceMode::Simulator) {
            SourceMode::Simulator => "SIMULATOR".cyan(),
            SourceMode::UdpWifi => "D1_MINI_UDP".bright_green().bold(),
            SourceMode::UsbSerial => "USB_SERIAL".yellow(),
            _ => "UNKNOWN".dimmed(),
        };

        let last_mv = chunk.samples.last().map_or(0.0, |s| s.filtered_mv);

        println!(
            "[{:>4}] {} | {:<11} | HR: {:>3} BPM | RR: {:>4} ms | HRV: {:>4.1} ms | {:>+5.2} mV | Trace: {}",
            format!("#{}", chunk.sequence_number).dimmed(),
            heart_icon,
            mode_str,
            metrics.heart_rate_bpm.to_string().bright_green().bold(),
            metrics.rr_interval_ms.to_string().yellow(),
            metrics.hrv_sdnn_ms.to_string().cyan(),
            last_mv,
            spark.bright_white()
        );
    }
}

fn display_cardiac_event(event: CardiacEvent) {
    let time_str = format_timestamp(event.timestamp_unix_millis).dimmed();
    let ev_type = CardiacEventType::try_from(event.event_type)
        .unwrap_or(CardiacEventType::CardiacEventUnspecified);

    let tag = match ev_type {
        CardiacEventType::RPeakDetected => "[R-PEAK]".bright_red().bold(),
        CardiacEventType::LeadOffTriggered => "[LEAD-OFF]".black().on_bright_red().bold(),
        CardiacEventType::LeadReconnected => "[LEAD-OK]".black().on_bright_green().bold(),
        CardiacEventType::BradycardiaTriggered => "[BRADYCARDIA]".black().on_bright_yellow().bold(),
        CardiacEventType::TachycardiaTriggered => "[TACHYCARDIA]".black().on_bright_magenta().bold(),
        CardiacEventType::SourceModeSwitched => "[MODE]".bright_cyan().bold(),
        _ => "[EVENT]".dimmed(),
    };

    println!("{} {} {:<4} BPM | RR: {:<4} ms | {}", time_str, tag, event.bpm, event.rr_interval_ms, event.description.bright_white());
}

fn display_log_entry(entry: LogEntry) {
    let time_str = format_timestamp(entry.timestamp_unix_millis).dimmed();
    let level_enum = LogLevel::try_from(entry.level).unwrap_or(LogLevel::Info);

    let level_tag = match level_enum {
        LogLevel::Debug => "[DEBUG]".cyan(),
        LogLevel::Info => "[INFO ]".bright_green(),
        LogLevel::Warn => "[WARN ]".bright_yellow().bold(),
        LogLevel::Error => "[ERROR]".bright_red().bold(),
    };

    let comp_tag = format!("[{}]", entry.component).magenta();
    println!("{} {} {:<10} {}", time_str, level_tag, comp_tag, entry.message);
}

async fn run_client(args: &Args) -> Result<(), Box<dyn std::error::Error>> {
    println!("{}", "Connecting to FlutBeat gRPC server...".dimmed());
    let mut client = TelemetryServiceClient::connect(args.server_url.clone()).await?;
    println!(
        "{} Connected to {}\n",
        "✓".bright_green().bold(),
        args.server_url.bright_cyan()
    );

    // Initial status query
    if let Ok(response) = client.get_status(GetStatusRequest {}).await {
        let status = response.into_inner();
        let mode = SourceMode::try_from(status.source_mode).unwrap_or(SourceMode::Simulator);
        let hr = status.metrics.as_ref().map_or(0, |m| m.heart_rate_bpm);
        println!("{}", "── Initial System Status ───────────────────────────────────".dimmed());
        println!(
            "  Uptime: {}s | Mode: {:?} | Samples Processed: {} | HR: {} BPM",
            status.uptime_seconds.to_string().yellow(),
            mode,
            status.total_samples_processed.to_string().cyan(),
            hr.to_string().bright_green()
        );
        println!("{}\n", "────────────────────────────────────────────────────────────".dimmed());
    }

    // Subscribe to ECG Waveform Stream
    let mut ecg_client = client.clone();
    let client_id_ecg = args.client_id.clone();
    let ecg_handle = tokio::spawn(async move {
        let req = StreamEcgRequest {
            client_id: client_id_ecg,
        };
        match ecg_client.stream_ecg(req).await {
            Ok(res) => {
                let mut stream = res.into_inner();
                while let Ok(Some(chunk)) = stream.message().await {
                    display_ecg_chunk(chunk);
                }
            }
            Err(e) => eprintln!("{} ECG stream error: {}", "[ERROR]".red(), e),
        }
    });

    // Subscribe to Cardiac Events Stream
    let mut event_client = client.clone();
    let client_id_events = args.client_id.clone();
    let events_handle = tokio::spawn(async move {
        let req = StreamEventsRequest {
            client_id: client_id_events,
        };
        match event_client.stream_cardiac_events(req).await {
            Ok(res) => {
                let mut stream = res.into_inner();
                while let Ok(Some(event)) = stream.message().await {
                    display_cardiac_event(event);
                }
            }
            Err(e) => eprintln!("{} Events stream error: {}", "[ERROR]".red(), e),
        }
    });

    // Subscribe to Log Stream
    let mut log_client = client.clone();
    let client_id_logs = args.client_id.clone();
    let min_level = parse_log_level(&args.min_level);
    let logs_handle = tokio::spawn(async move {
        let req = StreamLogsRequest {
            client_id: client_id_logs,
            min_level: min_level.into(),
        };
        match log_client.stream_logs(req).await {
            Ok(res) => {
                let mut stream = res.into_inner();
                while let Ok(Some(log_entry)) = stream.message().await {
                    display_log_entry(log_entry);
                }
            }
            Err(e) => eprintln!("{} Log stream error: {}", "[ERROR]".red(), e),
        }
    });

    tokio::select! {
        _ = ecg_handle => {},
        _ = events_handle => {},
        _ = logs_handle => {},
        _ = tokio::signal::ctrl_c() => {
            println!("\n{}", "Exiting ECG receiver...".dimmed());
        }
    }

    Ok(())
}

#[tokio::main]
async fn main() {
    let args = Args::parse();

    println!("{}", "=========================================================".bright_red());
    println!("{}", "   ❤️  FlutBeat — Live ECG Oscilloscope & Telemetry Receiver".bright_red().bold());
    println!("   Server: {} | Min Level: {}", args.server_url.yellow(), args.min_level.yellow());
    println!("{}", "=========================================================\n".bright_red());

    while let Err(e) = run_client(&args).await {
        eprintln!(
            "{} Connection failed: {}. Retrying in 3s...",
            "[WARN]".yellow(),
            e
        );
        sleep(Duration::from_secs(3)).await;
    }
}
