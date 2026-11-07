pub mod proto {
    tonic::include_proto!("telemetry.v1");
}

pub mod dsp;
pub mod ingest;
pub mod server;
pub mod simulator;

pub use dsp::{adc_to_mv, EcgDspPipeline, SAMPLE_RATE_HZ};
pub use ingest::{spawn_simulator_task, spawn_udp_listener, DEFAULT_UDP_PORT};
pub use proto::telemetry_service_client::TelemetryServiceClient;
pub use proto::telemetry_service_server::{TelemetryService, TelemetryServiceServer};
pub use proto::*;
pub use server::{now_millis, SharedState, TelemetryServiceImpl};
pub use simulator::EcgSimulator;

use chrono::{Local, TimeZone};

/// Helper to convert unix timestamp in millis to formatted local string
pub fn format_timestamp(millis: i64) -> String {
    let secs = millis / 1000;
    let nsecs = ((millis % 1000) * 1_000_000) as u32;
    if let Some(dt) = Local.timestamp_opt(secs, nsecs).single() {
        dt.format("%Y-%m-%d %H:%M:%S%.3f").to_string()
    } else {
        format!("{}ms", millis)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_timestamp_non_empty() {
        let ts = 1771488000000; // valid millis
        let formatted = format_timestamp(ts);
        assert!(!formatted.is_empty());
    }

    #[test]
    fn test_protobuf_enum_conversions() {
        assert_eq!(SourceMode::try_from(1), Ok(SourceMode::Simulator));
        assert_eq!(SourceMode::try_from(2), Ok(SourceMode::UdpWifi));
        assert_eq!(SourceMode::try_from(3), Ok(SourceMode::UsbSerial));

        assert_eq!(LeadStatus::try_from(1), Ok(LeadStatus::LeadsConnected));
        assert_eq!(LeadStatus::try_from(2), Ok(LeadStatus::LeadOffPositive));
        assert_eq!(LeadStatus::try_from(3), Ok(LeadStatus::LeadOffNegative));
        assert_eq!(LeadStatus::try_from(4), Ok(LeadStatus::LeadOffBoth));

        assert_eq!(RhythmClassification::try_from(1), Ok(RhythmClassification::NormalSinus));
        assert_eq!(RhythmClassification::try_from(2), Ok(RhythmClassification::Bradycardia));
        assert_eq!(RhythmClassification::try_from(3), Ok(RhythmClassification::Tachycardia));
    }
}
