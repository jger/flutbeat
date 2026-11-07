use std::net::SocketAddr;
use std::sync::Arc;
use std::time::Duration;

use tokio::net::TcpListener;
use tokio_stream::wrappers::TcpListenerStream;
use tonic::transport::Server;

use flutbeat_backend::proto::telemetry_service_client::TelemetryServiceClient;
use flutbeat_backend::proto::telemetry_service_server::TelemetryServiceServer;
use flutbeat_backend::proto::{
    ConfigureSourceRequest, GetStatusRequest, LogLevel, SourceMode, StreamEcgRequest,
    StreamEventsRequest, StreamLogsRequest,
};
use flutbeat_backend::{SharedState, TelemetryServiceImpl};

async fn spawn_test_server() -> (SocketAddr, Arc<SharedState>) {
    let state = Arc::new(SharedState::new());
    let service = TelemetryServiceImpl::new(state.clone());

    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        Server::builder()
            .add_service(TelemetryServiceServer::new(service))
            .serve_with_incoming(TcpListenerStream::new(listener))
            .await
            .unwrap();
    });

    (addr, state)
}

#[tokio::test]
async fn test_grpc_get_status_and_configure_source() {
    let (addr, _state) = spawn_test_server().await;
    let server_url = format!("http://{}", addr);

    let mut client = TelemetryServiceClient::connect(server_url).await.unwrap();

    // 1. Initial status
    let res = client.get_status(GetStatusRequest {}).await.unwrap().into_inner();
    assert_eq!(res.source_mode, SourceMode::Simulator as i32);
    assert_eq!(res.target_sim_bpm, 72);

    // 2. Configure source to UDP_WIFI with 85 target BPM
    let configured = client
        .configure_source(ConfigureSourceRequest {
            source_mode: SourceMode::UdpWifi as i32,
            target_sim_bpm: 85,
            reset_dsp: true,
        })
        .await
        .unwrap()
        .into_inner();

    assert_eq!(configured.source_mode, SourceMode::UdpWifi as i32);
    assert_eq!(configured.target_sim_bpm, 85);
}

#[tokio::test]
async fn test_grpc_stream_ecg_and_events() {
    let (addr, state) = spawn_test_server().await;
    let server_url = format!("http://{}", addr);

    let mut client = TelemetryServiceClient::connect(server_url).await.unwrap();

    // Subscribe to ECG stream
    let mut ecg_stream = client
        .stream_ecg(StreamEcgRequest {
            client_id: "test-ecg-client".to_string(),
        })
        .await
        .unwrap()
        .into_inner();

    // Subscribe to events stream
    let mut event_stream = client
        .stream_cardiac_events(StreamEventsRequest {
            client_id: "test-events-client".to_string(),
        })
        .await
        .unwrap()
        .into_inner();

    tokio::time::sleep(Duration::from_millis(50)).await;

    // Ingest a batch of simulated samples
    let sample_batch = vec![
        (512, false, false),
        (520, false, false),
        (980, false, false), // Prominent QRS spike
        (512, false, false),
    ];
    state.ingest_raw_batch(sample_batch, SourceMode::Simulator);

    // Verify ECG chunk received
    let chunk = ecg_stream.message().await.unwrap().expect("ecg chunk");
    assert_eq!(chunk.samples.len(), 4);
    assert_eq!(chunk.sample_rate_hz, 250);
    assert!(chunk.metrics.is_some());

    // Ingest Lead-Off transition
    let lead_off_batch = vec![(1023, true, false)];
    state.ingest_raw_batch(lead_off_batch, SourceMode::Simulator);

    // Verify Lead-Off event received
    let event = event_stream.message().await.unwrap().expect("cardiac event");
    assert!(event.description.contains("Lead-Off") || event.event_type > 0);
}

#[tokio::test]
async fn test_grpc_stream_logs_filtering() {
    let (addr, state) = spawn_test_server().await;
    let server_url = format!("http://{}", addr);

    let mut client_warn = TelemetryServiceClient::connect(server_url).await.unwrap();

    let mut stream_warn = client_warn
        .stream_logs(StreamLogsRequest {
            client_id: "warn-listener".to_string(),
            min_level: LogLevel::Warn as i32,
        })
        .await
        .unwrap()
        .into_inner();

    tokio::time::sleep(Duration::from_millis(50)).await;

    state.log(LogLevel::Debug, "dsp", "Debug log should be filtered");
    state.log(LogLevel::Info, "network", "Info log should be filtered");
    state.log(LogLevel::Warn, "cardiac", "Bradycardia warning threshold");
    state.log(LogLevel::Error, "sensor", "Electrode detached");

    let mut received_logs = Vec::new();
    while received_logs.len() < 2 {
        if let Some(msg) = stream_warn.message().await.unwrap() {
            if msg.component != "grpc" {
                received_logs.push(msg);
            }
        }
    }

    assert_eq!(received_logs[0].level, LogLevel::Warn as i32);
    assert_eq!(received_logs[0].component, "cardiac");
    assert_eq!(received_logs[1].level, LogLevel::Error as i32);
    assert_eq!(received_logs[1].component, "sensor");
}
