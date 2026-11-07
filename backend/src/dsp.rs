use std::collections::VecDeque;
use crate::proto::{LeadStatus, RhythmClassification, CardiacMetrics};

pub const SAMPLE_RATE_HZ: f32 = 250.0;
pub const ADC_MAX: f32 = 1023.0;
pub const VREF_MV: f32 = 3200.0; // 3.2V voltage divider on D1 Mini A0
pub const AD8232_GAIN: f32 = 1100.0; // AD8232 instrumentation amp (100x) + filter stage (11x) = 1100 V/V

/// Convert raw 10-bit ADC reading (0..1023) to physiological millivolts
pub fn adc_to_mv(raw_adc: u32) -> f32 {
    let centered = raw_adc as f32 - (ADC_MAX / 2.0);
    // (ADC / 1023) * 3200 mV / 100 gain -> physiological cardiac signal (-1.6mV to +1.6mV)
    (centered * (VREF_MV / ADC_MAX)) / AD8232_GAIN
}

/// 0.5 Hz High-Pass DC-blocking filter (eliminates baseline wander)
#[derive(Debug, Clone, Default)]
pub struct DcBlocker {
    prev_x: f32,
    prev_y: f32,
    alpha: f32,
}

impl DcBlocker {
    pub fn new() -> Self {
        // alpha = 0.992 gives fc ~0.5 Hz at 250 Hz sample rate
        Self {
            prev_x: 0.0,
            prev_y: 0.0,
            alpha: 0.992,
        }
    }

    pub fn process(&mut self, x: f32) -> f32 {
        let y = x - self.prev_x + self.alpha * self.prev_y;
        self.prev_x = x;
        self.prev_y = y;
        y
    }

    pub fn reset(&mut self) {
        self.prev_x = 0.0;
        self.prev_y = 0.0;
    }
}

/// 50 Hz Biquad Notch Filter at 250 Hz sampling rate to suppress mains hum
#[derive(Debug, Clone)]
pub struct NotchFilter50Hz {
    x1: f32,
    x2: f32,
    y1: f32,
    y2: f32,
    b0: f32,
    b1: f32,
    b2: f32,
    a1: f32,
    a2: f32,
}

impl NotchFilter50Hz {
    pub fn new() -> Self {
        // 50 Hz notch at 250 Hz sampling (w0 = 2*pi*50/250 = 0.4*pi, Q=10)
        // Pre-computed normalized IIR biquad coefficients
        let w0 = 2.0 * std::f32::consts::PI * 50.0 / SAMPLE_RATE_HZ;
        let q = 8.0;
        let alpha = (w0.sin()) / (2.0 * q);
        let cos_w0 = w0.cos();

        let b0 = 1.0;
        let b1 = -2.0 * cos_w0;
        let b2 = 1.0;
        let a0 = 1.0 + alpha;
        let a1 = -2.0 * cos_w0;
        let a2 = 1.0 - alpha;

        Self {
            x1: 0.0,
            x2: 0.0,
            y1: 0.0,
            y2: 0.0,
            b0: b0 / a0,
            b1: b1 / a0,
            b2: b2 / a0,
            a1: a1 / a0,
            a2: a2 / a0,
        }
    }

    pub fn process(&mut self, x: f32) -> f32 {
        let y = self.b0 * x + self.b1 * self.x1 + self.b2 * self.x2 - self.a1 * self.y1 - self.a2 * self.y2;
        self.x2 = self.x1;
        self.x1 = x;
        self.y2 = self.y1;
        self.y1 = y;
        y
    }

    pub fn reset(&mut self) {
        self.x1 = 0.0;
        self.x2 = 0.0;
        self.y1 = 0.0;
        self.y2 = 0.0;
    }
}

impl Default for NotchFilter50Hz {
    fn default() -> Self {
        Self::new()
    }
}

/// 40 Hz Low-Pass Smoothing Filter to reduce high-frequency muscle noise
#[derive(Debug, Clone)]
pub struct LowPass40Hz {
    x1: f32,
    x2: f32,
    y1: f32,
    y2: f32,
    b0: f32,
    b1: f32,
    b2: f32,
    a1: f32,
    a2: f32,
}

impl Default for LowPass40Hz {
    fn default() -> Self {
        Self::new()
    }
}

impl LowPass40Hz {
    pub fn new() -> Self {
        // 2nd-order Butterworth lowpass at 40 Hz (fs = 250 Hz)
        let w0 = 2.0 * std::f32::consts::PI * 40.0 / SAMPLE_RATE_HZ;
        let cos_w0 = w0.cos();
        let sin_w0 = w0.sin();
        let alpha = sin_w0 / (2.0 * std::f32::consts::FRAC_1_SQRT_2);

        let b0 = (1.0 - cos_w0) / 2.0;
        let b1 = 1.0 - cos_w0;
        let b2 = (1.0 - cos_w0) / 2.0;
        let a0 = 1.0 + alpha;
        let a1 = -2.0 * cos_w0;
        let a2 = 1.0 - alpha;

        Self {
            x1: 0.0,
            x2: 0.0,
            y1: 0.0,
            y2: 0.0,
            b0: b0 / a0,
            b1: b1 / a0,
            b2: b2 / a0,
            a1: a1 / a0,
            a2: a2 / a0,
        }
    }

    pub fn process(&mut self, x: f32) -> f32 {
        let y = self.b0 * x + self.b1 * self.x1 + self.b2 * self.x2 - self.a1 * self.y1 - self.a2 * self.y2;
        self.x2 = self.x1;
        self.x1 = x;
        self.y2 = self.y1;
        self.y1 = y;
        y
    }

    pub fn reset(&mut self) {
        self.x1 = 0.0;
        self.x2 = 0.0;
        self.y1 = 0.0;
        self.y2 = 0.0;
    }
}

/// Pan-Tompkins QRS Detection Engine
#[derive(Debug, Clone)]
pub struct PanTompkinsDetector {
    deriv_buffer: [f32; 5],
    deriv_idx: usize,
    mwi_buffer: VecDeque<f32>,
    mwi_window_size: usize,
    mwi_sum: f32,
    threshold: f32,
    noise_level: f32,
    signal_level: f32,
    refractory_samples: usize,
    refractory_count: usize,
}

impl Default for PanTompkinsDetector {
    fn default() -> Self {
        Self::new()
    }
}

impl PanTompkinsDetector {
    pub fn new() -> Self {
        let window_size = (0.12 * SAMPLE_RATE_HZ) as usize; // 120 ms integration window (30 samples)
        Self {
            deriv_buffer: [0.0; 5],
            deriv_idx: 0,
            mwi_buffer: VecDeque::with_capacity(window_size + 1),
            mwi_window_size: window_size.max(1),
            mwi_sum: 0.0,
            threshold: 0.005,
            noise_level: 0.001,
            signal_level: 0.02,
            refractory_samples: (0.20 * SAMPLE_RATE_HZ) as usize, // 200 ms refractory period (50 samples)
            refractory_count: 0,
        }
    }

    pub fn process(&mut self, filtered_sample: f32) -> bool {
        // 1. Derivative: y[n] = (2x[n] + x[n-1] - x[n-3] - 2x[n-4]) / 8
        self.deriv_buffer[self.deriv_idx] = filtered_sample;
        let x0 = self.deriv_buffer[self.deriv_idx];
        let x1 = self.deriv_buffer[(self.deriv_idx + 4) % 5];
        let x3 = self.deriv_buffer[(self.deriv_idx + 2) % 5];
        let x4 = self.deriv_buffer[(self.deriv_idx + 1) % 5];
        self.deriv_idx = (self.deriv_idx + 1) % 5;

        let deriv = (2.0 * x0 + x1 - x3 - 2.0 * x4) / 8.0;

        // 2. Squaring
        let squared = deriv * deriv;

        // 3. Moving-Window Integration (MWI)
        self.mwi_buffer.push_back(squared);
        self.mwi_sum += squared;
        if self.mwi_buffer.len() > self.mwi_window_size {
            if let Some(old) = self.mwi_buffer.pop_front() {
                self.mwi_sum = (self.mwi_sum - old).max(0.0);
            }
        }
        let mwi_val = self.mwi_sum / (self.mwi_window_size as f32);

        // 4. Refractory countdown
        if self.refractory_count > 0 {
            self.refractory_count -= 1;
            return false;
        }

        // 5. Adaptive threshold check
        if mwi_val > self.threshold {
            // R-peak confirmed
            self.signal_level = 0.125 * mwi_val + 0.875 * self.signal_level;
            self.threshold = self.noise_level + 0.25 * (self.signal_level - self.noise_level);
            self.refractory_count = self.refractory_samples;
            true
        } else {
            // Background noise update
            self.noise_level = 0.125 * mwi_val + 0.875 * self.noise_level;
            self.threshold = self.noise_level + 0.25 * (self.signal_level - self.noise_level);
            false
        }
    }

    pub fn reset(&mut self) {
        self.deriv_buffer = [0.0; 5];
        self.deriv_idx = 0;
        self.mwi_buffer.clear();
        self.mwi_sum = 0.0;
        self.threshold = 0.08;
        self.noise_level = 0.02;
        self.signal_level = 0.25;
        self.refractory_count = 0;
    }
}

/// Complete Real-Time ECG Digital Signal Processing & Analytics Pipeline
#[derive(Debug, Clone)]
pub struct EcgDspPipeline {
    dc_blocker: DcBlocker,
    notch_filter: NotchFilter50Hz,
    low_pass: LowPass40Hz,
    detector: PanTompkinsDetector,
    sample_count: u64,
    last_r_peak_sample: Option<u64>,
    rr_intervals_ms: VecDeque<u32>,
    total_beats: u64,
    current_bpm: u32,
    current_rr_ms: u32,
    last_beat_ts_ms: i64,
}

impl Default for EcgDspPipeline {
    fn default() -> Self {
        Self::new()
    }
}

impl EcgDspPipeline {
    pub fn new() -> Self {
        Self {
            dc_blocker: DcBlocker::new(),
            notch_filter: NotchFilter50Hz::new(),
            low_pass: LowPass40Hz::new(),
            detector: PanTompkinsDetector::new(),
            sample_count: 0,
            last_r_peak_sample: None,
            rr_intervals_ms: VecDeque::with_capacity(32),
            total_beats: 0,
            current_bpm: 72,
            current_rr_ms: 833,
            last_beat_ts_ms: 0,
        }
    }

    /// Process a single incoming sample (raw ADC reading) with timestamp and lead-off flags.
    /// Returns (filtered_mv, is_r_peak).
    pub fn process_sample(
        &mut self,
        raw_adc: u32,
        timestamp_ms: i64,
        lead_off: bool,
    ) -> (f32, bool) {
        self.sample_count += 1;

        if lead_off {
            // Signal invalid during electrode disconnection
            return (0.0, false);
        }

        let raw_mv = adc_to_mv(raw_adc);

        // Stage 1: DC Blocker (High-pass 0.5 Hz)
        let s1 = self.dc_blocker.process(raw_mv);

        // Stage 2: 50 Hz Notch Filter
        let s2 = self.notch_filter.process(s1);

        // Stage 3: Low-pass Smoothing (40 Hz)
        let filtered_mv = self.low_pass.process(s2);

        // Stage 4: Pan-Tompkins QRS R-Peak Detection
        let is_r_peak = self.detector.process(filtered_mv);

        if is_r_peak {
            self.total_beats += 1;
            self.last_beat_ts_ms = timestamp_ms;

            if let Some(last_sample) = self.last_r_peak_sample {
                let delta_samples = self.sample_count - last_sample;
                let rr_ms = ((delta_samples as f32 / SAMPLE_RATE_HZ) * 1000.0) as u32;

                // Validate physiologically plausible R-R interval (300 ms - 2000 ms, i.e. 30 - 200 BPM)
                if (300..=2000).contains(&rr_ms) {
                    self.current_rr_ms = rr_ms;
                    self.current_bpm = (60000.0 / rr_ms as f32).round() as u32;

                    self.rr_intervals_ms.push_back(rr_ms);
                    if self.rr_intervals_ms.len() > 30 {
                        self.rr_intervals_ms.pop_front();
                    }
                }
            }
            self.last_r_peak_sample = Some(self.sample_count);
        }

        (filtered_mv, is_r_peak)
    }

    /// Computes instantaneous and rolling cardiac metrics
    pub fn compute_metrics(&self, lo_plus: bool, lo_minus: bool) -> CardiacMetrics {
        let lead_status = match (lo_plus, lo_minus) {
            (false, false) => LeadStatus::LeadsConnected,
            (true, false) => LeadStatus::LeadOffPositive,
            (false, true) => LeadStatus::LeadOffNegative,
            (true, true) => LeadStatus::LeadOffBoth,
        };

        let is_lead_off = lo_plus || lo_minus;

        // Calculate HRV SDNN & RMSSD over the last 30 beats
        let (sdnn, rmssd) = if self.rr_intervals_ms.len() >= 3 {
            let n = self.rr_intervals_ms.len() as f32;
            let sum: f32 = self.rr_intervals_ms.iter().map(|&v| v as f32).sum();
            let mean = sum / n;

            let variance = self.rr_intervals_ms
                .iter()
                .map(|&v| {
                    let diff = v as f32 - mean;
                    diff * diff
                })
                .sum::<f32>() / (n - 1.0);
            let sdnn = variance.sqrt();

            let mut diff_sum_sq = 0.0;
            for i in 1..self.rr_intervals_ms.len() {
                let diff = self.rr_intervals_ms[i] as f32 - self.rr_intervals_ms[i - 1] as f32;
                diff_sum_sq += diff * diff;
            }
            let rmssd = (diff_sum_sq / (n - 1.0)).sqrt();

            (sdnn, rmssd)
        } else {
            (35.0, 28.0) // Nominal baseline HRV prior to accumulating beats
        };

        // Determine clinical rhythm classification
        let rhythm = if is_lead_off || self.current_bpm == 0 {
            RhythmClassification::NoSignal
        } else if self.current_bpm < 60 {
            RhythmClassification::Bradycardia
        } else if self.current_bpm > 100 {
            RhythmClassification::Tachycardia
        } else if sdnn > 65.0 {
            RhythmClassification::IrregularArrhythmia
        } else {
            RhythmClassification::NormalSinus
        };

        let signal_quality = if is_lead_off {
            0
        } else if self.rr_intervals_ms.is_empty() {
            75
        } else {
            98
        };

        CardiacMetrics {
            heart_rate_bpm: if is_lead_off { 0 } else { self.current_bpm },
            rr_interval_ms: if is_lead_off { 0 } else { self.current_rr_ms },
            hrv_sdnn_ms: if is_lead_off { 0.0 } else { (sdnn * 10.0).round() / 10.0 },
            hrv_rmssd_ms: if is_lead_off { 0.0 } else { (rmssd * 10.0).round() / 10.0 },
            lead_status: lead_status as i32,
            rhythm: rhythm as i32,
            signal_quality_percent: signal_quality,
            total_beats: self.total_beats,
            last_beat_timestamp_ms: self.last_beat_ts_ms,
        }
    }

    pub fn reset(&mut self) {
        self.dc_blocker.reset();
        self.notch_filter.reset();
        self.low_pass.reset();
        self.detector.reset();
        self.sample_count = 0;
        self.last_r_peak_sample = None;
        self.rr_intervals_ms.clear();
        self.total_beats = 0;
        self.current_bpm = 72;
        self.current_rr_ms = 833;
        self.last_beat_ts_ms = 0;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_adc_to_mv_mapping() {
        let baseline = adc_to_mv(512);
        assert!(baseline.abs() < 0.05, "Baseline 512 should be ~0 mV, got {}", baseline);

        let max_val = adc_to_mv(1023);
        assert!(max_val > 1.4 && max_val < 1.7, "1023 ADC should map to ~1.6 mV, got {}", max_val);

        let min_val = adc_to_mv(0);
        assert!(min_val < -1.4 && min_val > -1.7, "0 ADC should map to ~-1.6 mV, got {}", min_val);
    }

    #[test]
    fn test_dc_blocker_removes_dc_offset() {
        let mut blocker = DcBlocker::new();
        // Feed constant DC 1.0 mV
        let mut out = 0.0;
        for _ in 0..500 {
            out = blocker.process(1.0);
        }
        assert!(out.abs() < 0.05, "DC blocker should attenuate steady DC to ~0, got {}", out);
    }

    #[test]
    fn test_pan_tompkins_r_peak_detection() {
        let mut detector = PanTompkinsDetector::new();
        let mut detected_peaks = 0;

        for step in 0..600 {
            // Emit realistic QRS wave spanning 10 samples every 250 samples (1 Hz = 60 BPM)
            let cycle = step % 250;
            let val = if (95..=105).contains(&cycle) {
                let dist = (cycle as f32 - 100.0).abs();
                1.4 * (-0.5 * (dist / 2.0).powi(2)).exp()
            } else {
                0.0
            };

            if detector.process(val) {
                detected_peaks += 1;
            }
        }

        assert!(detected_peaks >= 1, "Expected at least 1 detected R-peak, got {}", detected_peaks);
    }
}
