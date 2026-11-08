/*
 * ==============================================================================
 * FlutBeat — Direct USB Serial OTG ECG Firmware for ESP (WeMos D1 Mini / ESP32)
 * ==============================================================================
 *
 * Direct Hardware-to-Mobile Connection (No Backend & No Wi-Fi required):
 * Connects directly to the Android phone/tablet via a physical USB-C OTG cable.
 *
 * Pin Connections (AD8232 Heart Monitor <-> WeMos D1 Mini ESP8266):
 * ------------------------------------------------------------------
 * AD8232 Pin | D1 Mini Pin | ESP8266 GPIO | Description
 * -----------+-------------+--------------+----------------------------------
 * 3.3V       | 3V3         | 3.3V Power   | Power supply from D1 Mini LDO
 * GND        | G           | GND          | Common ground
 * OUTPUT     | A0          | ADC0 (A0)    | Analog ECG voltage (0 - 3.2V)
 * LO+        | D5          | GPIO14       | Lead-Off Detection (+) [Active HIGH]
 * LO-        | D6          | GPIO12       | Lead-Off Detection (-) [Active HIGH]
 * SDN        | D7          | GPIO13       | Shutdown control (Driven HIGH)
 *
 * Serial Protocol:
 * Streams 250 Hz CSV frames over USB Serial at 115200 baud (8-N-1):
 *   "<adc_value>,<lo_plus>,<lo_minus>\n"
 *   e.g.: "512,0,0\n"
 * ==============================================================================
 */

#include <Arduino.h>

// -----------------------------------------------------------------------------
// Hardware Pin Definitions (WeMos D1 Mini / ESP8266)
// -----------------------------------------------------------------------------
#ifndef PIN_ECG_ANALOG
  #define PIN_ECG_ANALOG  A0      // ADC0 (0 - 1023, 0 - 3.2V)
#endif

#ifndef PIN_LEAD_OFF_P
  #define PIN_LEAD_OFF_P  D5      // GPIO14 (LO+)
#endif

#ifndef PIN_LEAD_OFF_N
  #define PIN_LEAD_OFF_N  D6      // GPIO12 (LO-)
#endif

#ifndef PIN_SHUTDOWN
  #define PIN_SHUTDOWN    D7      // GPIO13 (SDN)
#endif

#ifndef PIN_STATUS_LED
  #define PIN_STATUS_LED  D4      // Built-in LED (GPIO2, active LOW)
#endif

// -----------------------------------------------------------------------------
// Sampling Parameters: 250 Hz = 4000 microseconds per sample
// -----------------------------------------------------------------------------
const unsigned long SAMPLE_INTERVAL_MICROS = 4000;
unsigned long lastSampleMicros = 0;

void flashLeds(int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    digitalWrite(PIN_STATUS_LED, LOW); // LED ON
    delay(delayMs);
    digitalWrite(PIN_STATUS_LED, HIGH); // LED OFF
    delay(delayMs);
  }
}

void setup() {
  // High-speed USB Serial OTG communication
  Serial.begin(115200);
  delay(100);

  // Configure Status LED
  pinMode(PIN_STATUS_LED, OUTPUT);
  flashLeds(3, 60); // 3 rapid blinks to signal boot ready

  // Configure AD8232 sensor pins
  pinMode(PIN_LEAD_OFF_P, INPUT);
  pinMode(PIN_LEAD_OFF_N, INPUT);
  pinMode(PIN_SHUTDOWN, OUTPUT);
  digitalWrite(PIN_SHUTDOWN, HIGH); // Enable AD8232 front-end amplifier

  lastSampleMicros = micros();
}

void loop() {
  unsigned long currentMicros = micros();

  // 1. Continuous Heartbeat Pulse LED: toggles every 500 ms (1 Hz visual pulse)
  static unsigned long lastBlinkMs = 0;
  if (millis() - lastBlinkMs >= 500) {
    lastBlinkMs = millis();
    digitalWrite(PIN_STATUS_LED, !digitalRead(PIN_STATUS_LED));
  }

  // 2. Deterministic 250 Hz sampling (every 4000 µs)
  if (currentMicros - lastSampleMicros >= SAMPLE_INTERVAL_MICROS) {
    lastSampleMicros += SAMPLE_INTERVAL_MICROS;

    // Read analog ECG voltage (0..1023)
    uint16_t adcVal = analogRead(PIN_ECG_ANALOG);

    // Read Lead-Off detection pins
    uint8_t loP = (digitalRead(PIN_LEAD_OFF_P) == HIGH) ? 1 : 0;
    uint8_t loN = (digitalRead(PIN_LEAD_OFF_N) == HIGH) ? 1 : 0;

    // Stream raw CSV sample directly to the Flutter app via USB OTG
    // Format: "adc,lo_plus,lo_minus\n"
    Serial.print(adcVal);
    Serial.print(',');
    Serial.print(loP);
    Serial.print(',');
    Serial.println(loN);
  }

  yield();
}
