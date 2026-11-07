use std::f32::consts::PI;
use crate::dsp::{SAMPLE_RATE_HZ, ADC_MAX, VREF_MV, AD8232_GAIN};

/// Morphological P-Q-R-S-T Synthetic ECG Generator
#[derive(Debug, Clone)]
pub struct EcgSimulator {
    target_bpm: u32,
    phase: f32, // [0, 2*PI)
    sample_index: u64,
    lead_off_active: bool,
}

impl EcgSimulator {
    pub fn new(target_bpm: u32) -> Self {
        Self {
            target_bpm: target_bpm.clamp(40, 180),
            phase: 0.0,
            sample_index: 0,
            lead_off_active: false,
        }
    }

    pub fn set_target_bpm(&mut self, bpm: u32) {
        self.target_bpm = bpm.clamp(40, 180);
    }

    pub fn target_bpm(&self) -> u32 {
        self.target_bpm
    }

    pub fn set_lead_off(&mut self, active: bool) {
        self.lead_off_active = active;
    }

    pub fn is_lead_off(&self) -> bool {
        self.lead_off_active
    }

    /// Advance the simulator by one sample (1 / 250 s = 4 ms)
    /// Returns (raw_adc: u32, lo_plus: bool, lo_minus: bool)
    pub fn next_sample(&mut self) -> (u32, bool, bool) {
        self.sample_index += 1;

        if self.lead_off_active {
            // When leads disconnect, the AD8232 rail pulls high/low with noise
            return (1023, true, true);
        }

        // Heart rate with natural Respiratory Sinus Arrhythmia (RSA) modulation (~0.2 Hz)
        let rsa_freq = 0.2; // 12 breaths per minute
        let rsa_amp = 0.04; // 4% heart rate modulation
        let time_sec = self.sample_index as f32 / SAMPLE_RATE_HZ;
        let instantaneous_bpm = self.target_bpm as f32 * (1.0 + rsa_amp * (2.0 * PI * rsa_freq * time_sec).sin());

        let frequency_hz = instantaneous_bpm / 60.0;
        let phase_step = (2.0 * PI * frequency_hz) / SAMPLE_RATE_HZ;
        self.phase = (self.phase + phase_step) % (2.0 * PI);

        // Normalize phase around R-peak (0) in range [-PI, +PI)
        let mut theta = self.phase;
        if theta > PI {
            theta -= 2.0 * PI;
        }

        // McSharry-style Gaussian P-Q-R-S-T wave components (center_rad, amplitude_mv, width_rad)
        let p_wave = gaussian(theta, -0.35 * PI, 0.16, 0.12);
        let q_wave = gaussian(theta, -0.09 * PI, -0.18, 0.04);
        let r_peak = gaussian(theta, 0.0, 1.45, 0.05);
        let s_wave = gaussian(theta, 0.09 * PI, -0.32, 0.04);
        let t_wave = gaussian(theta, 0.48 * PI, 0.32, 0.22);

        // Base physiological cardiac mV
        let cardiac_mv = p_wave + q_wave + r_peak + s_wave + t_wave;

        // Subtle high-frequency physiological baseline noise (~0.015 mV)
        let noise = 0.015 * ((13.0 * self.phase).sin() + (29.0 * self.phase).cos());
        let total_mv = cardiac_mv + noise;

        // Convert physiological mV back to 10-bit raw ADC reading (0..1023)
        // total_mv = ((adc - 512) * (3200 / 1023)) / 100
        // (adc - 512) = total_mv * 100 * 1023 / 3200
        let centered_adc = (total_mv * AD8232_GAIN * ADC_MAX) / VREF_MV;
        let raw_adc = (512.0 + centered_adc).clamp(0.0, 1023.0).round() as u32;

        (raw_adc, false, false)
    }
}

fn gaussian(theta: f32, center: f32, amplitude: f32, width: f32) -> f32 {
    let diff = theta - center;
    amplitude * (-0.5 * (diff / width).powi(2)).exp()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_simulator_generates_valid_adc_range() {
        let mut sim = EcgSimulator::new(75);
        for _ in 0..1000 {
            let (adc, lo_p, lo_n) = sim.next_sample();
            assert!(adc <= 1023, "ADC value exceeded 1023: {}", adc);
            assert!(!lo_p);
            assert!(!lo_n);
        }
    }

    #[test]
    fn test_simulator_r_peak_reaches_expected_peak() {
        let mut sim = EcgSimulator::new(60);
        let mut max_adc = 0;
        for _ in 0..250 {
            let (adc, _, _) = sim.next_sample();
            if adc > max_adc {
                max_adc = adc;
            }
        }
        // R-peak of ~1.45 mV corresponds to centered ADC of:
        // 1.45 * 100 * 1023 / 3200 ~ 463 -> 512 + 463 ~ 975 ADC
        assert!(max_adc > 850, "Expected prominent R-peak ADC > 850, got {}", max_adc);
    }
}

