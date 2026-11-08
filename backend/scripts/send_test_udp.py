#!/usr/bin/env python3
"""
FlutBeat — Standalone Synthetic ECG UDP Test Signal Injector
Simulates a WeMos D1 Mini (ESP8266) streaming 250 Hz batched ECG data over Wi-Fi UDP.
"""

import argparse
import json
import math
import socket
import sys
import time

SAMPLE_RATE_HZ = 250.0
BATCH_SIZE = 10
BATCH_INTERVAL_SEC = BATCH_SIZE / SAMPLE_RATE_HZ  # 0.040s = 40ms

# AD8232 & ADC Constants matching Rust DSP
VREF_MV = 3200.0
ADC_MAX = 1023.0
AD8232_GAIN = 100.0


def gaussian(theta: float, center: float, amplitude: float, width: float) -> float:
    diff = theta - center
    return amplitude * math.exp(-0.5 * (diff / width) ** 2)


def generate_sample(sample_index: int, phase: float, target_bpm: float, lead_off: bool) -> tuple[int, int, int, float]:
    """
    Returns (adc_val, lo_plus, lo_minus, next_phase)
    """
    if lead_off:
        return 1023, 1, 1, phase

    # Respiratory Sinus Arrhythmia (RSA) modulation
    rsa_freq = 0.2
    rsa_amp = 0.04
    t_sec = sample_index / SAMPLE_RATE_HZ
    instant_bpm = target_bpm * (1.0 + rsa_amp * math.sin(2.0 * math.pi * rsa_freq * t_sec))

    freq_hz = instant_bpm / 60.0
    phase_step = (2.0 * math.pi * freq_hz) / SAMPLE_RATE_HZ
    phase = (phase + phase_step) % (2.0 * math.pi)

    theta = phase
    if theta > math.pi:
        theta -= 2.0 * math.pi

    # McSharry-style Gaussian P-Q-R-S-T wave components
    p_wave = gaussian(theta, -0.35 * math.pi, 0.16, 0.12)
    q_wave = gaussian(theta, -0.09 * math.pi, -0.18, 0.04)
    r_peak = gaussian(theta, 0.0, 1.45, 0.05)
    s_wave = gaussian(theta, 0.09 * math.pi, -0.32, 0.04)
    t_wave = gaussian(theta, 0.48 * math.pi, 0.32, 0.22)

    cardiac_mv = p_wave + q_wave + r_peak + s_wave + t_wave
    noise = 0.015 * (math.sin(13.0 * phase) + math.cos(29.0 * phase))
    total_mv = cardiac_mv + noise

    centered_adc = (total_mv * AD8232_GAIN * ADC_MAX) / VREF_MV
    raw_adc = int(round(max(0.0, min(1023.0, 512.0 + centered_adc))))

    return raw_adc, 0, 0, phase


def main():
    parser = argparse.ArgumentParser(
        description="FlutBeat — Synthetic ECG UDP Test Signal Injector (D1 Mini Mock)"
    )
    parser.add_argument("--host", default="127.0.0.1", help="Target backend IP (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=50052, help="Target UDP port (default: 50052)")
    parser.add_argument("--bpm", type=int, default=72, help="Target heart rate in BPM (default: 72)")
    parser.add_argument("--lead-off", action="store_true", help="Simulate disconnected electrodes (LO+/LO- active)")
    parser.add_argument("--duration", type=int, default=0, help="Transmission duration in seconds (0 = infinite)")

    args = parser.parse_args()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    dest = (args.host, args.port)

    print("==================================================")
    print("  FlutBeat — UDP Test Signal Injector (D1 Mini)")
    print(f"  Target:     {args.host}:{args.port}")
    print(f"  Heart Rate: {args.bpm} BPM")
    print(f"  Electrodes: {'DISCONNECTED (Lead-Off)' if args.lead_off else 'CONNECTED'}")
    print(f"  Streaming:  250 Hz (10 samples / 40 ms)")
    print("==================================================")
    print("Press Ctrl+C to stop transmitting.")

    seq = 0
    sample_index = 0
    phase = 0.0
    start_time = time.time()
    next_batch_time = time.perf_counter()

    try:
        while True:
            batch = []
            for _ in range(BATCH_SIZE):
                sample_index += 1
                adc, lo_p, lo_n, phase = generate_sample(sample_index, phase, args.bpm, args.lead_off)
                batch.append([adc, lo_p, lo_n])

            seq += 1
            payload = {
                "seq": seq,
                "ts": int(time.time() * 1000),
                "s": batch,
            }
            data = json.dumps(payload, separators=(",", ":")).encode("utf-8")
            sock.sendto(data, dest)

            if seq % 25 == 0:  # Every ~1 second
                elapsed = time.time() - start_time
                total_samples = seq * BATCH_SIZE
                print(
                    f"\r[UDP Injector] Packets: {seq:5d} | Samples: {total_samples:6d} | Elapsed: {elapsed:5.1f}s | Target: {args.bpm} BPM",
                    end="",
                    flush=True,
                )

            if args.duration > 0 and (time.time() - start_time) >= args.duration:
                print("\nDuration reached. Stopping test signal.")
                break

            next_batch_time += BATCH_INTERVAL_SEC
            sleep_time = next_batch_time - time.perf_counter()
            if sleep_time > 0:
                time.sleep(sleep_time)
            else:
                next_batch_time = time.perf_counter()

    except KeyboardInterrupt:
        print("\nTransmission stopped by user.")


if __name__ == "__main__":
    main()

