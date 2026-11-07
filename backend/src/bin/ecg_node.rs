use std::net::SocketAddr;
use std::sync::atomic::Ordering;
use std::sync::Arc;
use std::time::Duration;

use clap::Parser;
use colored::Colorize;
use tonic::transport::Server;

use flutbeat_backend::proto::telemetry_service_server::TelemetryServiceServer;
use flutbeat_backend::proto::{LogLevel, SourceMode};
use flutbeat_backend::{
    spawn_simulator_task, spawn_udp_listener, SharedState, TelemetryServiceImpl,
    DEFAULT_UDP_PORT,
};

#[derive(Parser, Debug)]
#[command(name = "ecg_node")]
#[command(about = "FlutBeat — AD8232 ECG Telemetry, DSP Engine & gRPC Node Service")]
struct Args {
    /// gRPC server listening port
    #[arg(short, long, default_value_t = 50051)]
    port: u16,

    /// UDP listening port for D1 Mini ESP8266 packets
    #[arg(short, long, default_value_t = DEFAULT_UDP_PORT)]
    udp_port: u16,

    /// Default starting ingestion mode (sim, udp)
    #[arg(short, long, default_value = "sim")]
    mode: String,

    /// Initial target simulator BPM (40 - 180)
    #[arg(short, long, default_value_t = 72)]
    bpm: u32,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    println!("{}", "==================================================".bright_red());
    println!("{}", "  ❤️  FlutBeat — ECG Hardware Node & DSP Service".bright_red().bold());
    println!("{}", "  AD8232 Single-Lead Monitor + WeMos D1 Mini      ".bright_white());
    println!("{}", "==================================================".bright_red());

    let state = Arc::new(SharedState::new());

    // Configure initial ingestion mode
    let initial_mode = match args.mode.to_lowercase().as_str() {
        "udp" | "wifi" => SourceMode::UdpWifi,
        _ => SourceMode::Simulator,
    };
    state.source_mode.store(initial_mode as i32, Ordering::SeqCst);
    state.target_sim_bpm.store(args.bpm, Ordering::SeqCst);
    {
        let mut sim = state.simulator.lock().await;
        sim.set_target_bpm(args.bpm);
    }

    // 1. Spawn Wi-Fi UDP background receiver
    spawn_udp_listener(state.clone(), args.udp_port);

    // 2. Spawn Synthetic ECG simulator background task
    spawn_simulator_task(state.clone());

    // 3. Spawn periodic 10-second heartbeat diagnostic logger
    spawn_heartbeat_logger(state.clone());

    // 4. Bind & launch Tonic gRPC server
    let addr: SocketAddr = format!("0.0.0.0:{}", args.port).parse()?;
    state.log(
        LogLevel::Info,
        "grpc",
        format!(
            "Starting FlutBeat gRPC telemetry server on {} [Mode: {:?}, Sim BPM: {}]",
            addr, initial_mode, args.bpm
        ),
    );

    Server::builder()
        .add_service(TelemetryServiceServer::new(TelemetryServiceImpl::new(
            state.clone(),
        )))
        .serve(addr)
        .await?;

    Ok(())
}

fn spawn_heartbeat_logger(state: Arc<SharedState>) {
    tokio::spawn(async move {
        let mut ticker = tokio::time::interval(Duration::from_secs(10));
        loop {
            ticker.tick().await;
            let uptime = state.start_time.elapsed().as_secs();
            let total_samples = state.total_samples.load(Ordering::Relaxed);
            let metrics = *state.latest_metrics.read().await;
            let mode = state.get_source_mode();

            state.log(
                LogLevel::Info,
                "health",
                format!(
                    "System Heartbeat | Uptime: {}s | Mode: {:?} | Samples: {} | HR: {} BPM | RR: {}ms | Beats: {}",
                    uptime, mode, total_samples, metrics.heart_rate_bpm, metrics.rr_interval_ms, metrics.total_beats
                ),
            );
        }
    });
}
