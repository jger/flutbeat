use std::net::SocketAddr;
use std::sync::Arc;
use std::time::Duration;
use serde::Deserialize;
use tokio::net::UdpSocket;
use tokio::time::sleep;

use crate::proto::{LogLevel, SourceMode};
use crate::server::SharedState;

pub const DEFAULT_UDP_PORT: u16 = 50052;

#[derive(Debug, Deserialize)]
struct UdpBatchJson {
    #[allow(dead_code)]
    seq: Option<u32>,
    #[allow(dead_code)]
    ts: Option<u64>,
    s: Vec<[u32; 3]>, // [[adc, lo_p, lo_n], ...]
}

/// Spawns the Wi-Fi UDP background listener on port 50052
pub fn spawn_udp_listener(state: Arc<SharedState>, port: u16) {
    tokio::spawn(async move {
        let addr = format!("0.0.0.0:{}", port);
        match UdpSocket::bind(&addr).await {
            Ok(socket) => {
                state.log(
                    LogLevel::Info,
                    "udp",
                    format!("Wi-Fi UDP receiver listening on {} for D1 Mini ESP8266 packets", addr),
                );

                let mut buf = [0u8; 1024];
                loop {
                    match socket.recv_from(&mut buf).await {
                        Ok((len, peer_addr)) => {
                            handle_udp_packet(&state, &buf[..len], peer_addr);
                        }
                        Err(e) => {
                            state.log(LogLevel::Warn, "udp", format!("UDP socket receive error: {}", e));
                            sleep(Duration::from_millis(500)).await;
                        }
                    }
                }
            }
            Err(e) => {
                state.log(
                    LogLevel::Error,
                    "udp",
                    format!("Failed to bind UDP socket on {}: {}. Will use simulator only.", addr, e),
                );
            }
        }
    });
}

fn handle_udp_packet(state: &SharedState, data: &[u8], peer_addr: SocketAddr) {
    // If not currently in UDP mode, switch automatically or notify
    if state.get_source_mode() != SourceMode::UdpWifi {
        state.log(
            LogLevel::Info,
            "udp",
            format!("Received D1 Mini packets from {}. Auto-switching mode to UDP_WIFI", peer_addr),
        );
        state.set_source_mode(SourceMode::UdpWifi);
    }

    if let Ok(text) = std::str::from_utf8(data) {
        let trimmed = text.trim();
        // Check if JSON batch
        if trimmed.starts_with('{') {
            if let Ok(batch) = serde_json::from_str::<UdpBatchJson>(trimmed) {
                let samples: Vec<(u32, bool, bool)> = batch.s
                    .into_iter()
                    .map(|item| (item[0], item[1] != 0, item[2] != 0))
                    .collect();
                state.ingest_raw_batch(samples, SourceMode::UdpWifi);
                return;
            }
        }

        // Fallback: line-delimited CSV "adc,lo_p,lo_n"
        let mut samples = Vec::new();
        for line in trimmed.lines() {
            let parts: Vec<&str> = line.split(',').collect();
            if parts.len() >= 3 {
                if let (Ok(adc), Ok(lo_p), Ok(lo_n)) = (
                    parts[0].trim().parse::<u32>(),
                    parts[1].trim().parse::<u32>(),
                    parts[2].trim().parse::<u32>(),
                ) {
                    samples.push((adc, lo_p != 0, lo_n != 0));
                }
            }
        }
        if !samples.is_empty() {
            state.ingest_raw_batch(samples, SourceMode::UdpWifi);
        }
    }
}

/// Spawns the Synthetic ECG simulator ticker.
/// When source mode is `SIMULATOR`, periodically generates 10 samples every 40 ms (250 Hz).
pub fn spawn_simulator_task(state: Arc<SharedState>) {
    tokio::spawn(async move {
        let mut ticker = tokio::time::interval(Duration::from_millis(40));
        loop {
            ticker.tick().await;

            // Only push simulated samples if currently in SIMULATOR mode
            if state.get_source_mode() == SourceMode::Simulator {
                let mut sim = state.simulator.lock().await;
                let mut batch = Vec::with_capacity(10);
                for _ in 0..10 {
                    batch.push(sim.next_sample());
                }
                drop(sim);

                state.ingest_raw_batch(batch, SourceMode::Simulator);
            }
        }
    });
}

