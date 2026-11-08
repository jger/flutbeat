/*
 * ==============================================================================
 * FlutBeat — AD8232 ECG Telemetry Firmware for WeMos D1 Mini (ESP8266)
 * ==============================================================================
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
 * Networking:
 * Streams 250 Hz batched ECG samples over Wi-Fi UDP (port 50052)
 * to the FlutBeat Rust backend (flutbeat_backend).
 * Also streams CSV output to USB Serial (74880 baud).
 * ==============================================================================
 */

#include <ESP8266WiFi.h>
#include <WiFiUdp.h>

// -----------------------------------------------------------------------------
// User Configuration — Update your Wi-Fi credentials & Host IP
// -----------------------------------------------------------------------------
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Target Rust gRPC backend IP address (where `ecg_node` is listening on UDP)
const char* TARGET_HOST_IP = "YOUR_COMPUTER_IP";
const uint16_t UDP_PORT    = 50052;

// -----------------------------------------------------------------------------
// Hardware Pin Definitions
// -----------------------------------------------------------------------------
#define PIN_ECG_ANALOG  A0      // ADC0 (0 - 1023, 0 - 3.2V on D1 Mini)
#define PIN_LEAD_OFF_P  D5      // GPIO14 (LO+)
#define PIN_LEAD_OFF_N  D6      // GPIO12 (LO-)
#define PIN_SHUTDOWN    D7      // GPIO13 (SDN)
#define PIN_STATUS_LED  D4      // Built-in LED on D1 Mini / ESP-12F (GPIO2, active LOW)

// -----------------------------------------------------------------------------
// Sampling Parameters
// -----------------------------------------------------------------------------
// 250 Hz = 4000 microseconds per sample
const unsigned long SAMPLE_INTERVAL_MICROS = 4000;
const int BATCH_SIZE = 10; // Send UDP packet every 10 samples (40 ms)

struct EcgPoint {
  uint16_t adc;
  uint8_t lo_plus;
  uint8_t lo_minus;
};

EcgPoint sampleBuffer[BATCH_SIZE];
int bufferIndex = 0;
unsigned long lastSampleMicros = 0;
uint32_t packetSequence = 0;

WiFiUDP udp;

void flashLeds(int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    digitalWrite(PIN_STATUS_LED, LOW); // LED ON
    #ifdef D0
    digitalWrite(D0, LOW);
    #endif
    delay(delayMs);
    digitalWrite(PIN_STATUS_LED, HIGH); // LED OFF
    #ifdef D0
    digitalWrite(D0, HIGH);
    #endif
    delay(delayMs);
  }
}

void setup() {
  // Use 74880 baud to match the ESP8266 hardware bootloader seamlessly!
  Serial.begin(74880);
  delay(300);

  // Configure Status LEDs
  pinMode(PIN_STATUS_LED, OUTPUT);
  #ifdef D0
  pinMode(D0, OUTPUT);
  #endif

  // 5 Fast visual confirmation blinks at startup (ON for 80ms, OFF for 80ms)
  flashLeds(5, 80);

  Serial.println();
  Serial.println(F("=================================================="));
  Serial.println(F("  ❤️  FlutBeat — AD8232 ECG Firmware (D1 Mini)   "));
  Serial.println(F("  Baud Rate: 74880 baud | Sampling: 250 Hz        "));
  Serial.println(F("=================================================="));
  Serial.println(F("[BOOT] Hardware initialized. Starting Wi-Fi setup..."));

  // Configure AD8232 sensor pins
  pinMode(PIN_LEAD_OFF_P, INPUT);
  pinMode(PIN_LEAD_OFF_N, INPUT);
  pinMode(PIN_SHUTDOWN, OUTPUT);
  digitalWrite(PIN_SHUTDOWN, HIGH); // Enable AD8232 front-end

  // Clean Wi-Fi initialization
  WiFi.persistent(false);
  WiFi.disconnect(true);
  delay(100);
  WiFi.mode(WIFI_STA);
  WiFi.setAutoConnect(false);

  Serial.printf("[WIFI] Connecting to SSID: '%s' ...\n", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 25) {
    delay(300);
    digitalWrite(PIN_STATUS_LED, !digitalRead(PIN_STATUS_LED)); // Toggle LED while waiting
    Serial.print(F("."));
    attempts++;
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("[WIFI] Connected! Board IP: %s\n", WiFi.localIP().toString().c_str());
    Serial.printf("[WIFI] Streaming UDP batches to %s:%u\n", TARGET_HOST_IP, UDP_PORT);
    digitalWrite(PIN_STATUS_LED, LOW); // Solid ON when connected to Wi-Fi
  } else {
    Serial.printf("[WIFI] Connection failed (status: %d). Continuing in USB Serial mode.\n", WiFi.status());
    digitalWrite(PIN_STATUS_LED, HIGH);
  }

  udp.begin(UDP_PORT);
  lastSampleMicros = micros();
  Serial.println(F("[RUN] ADC sampling loop active @ 250 Hz."));
}

void loop() {
  unsigned long currentMicros = micros();

  // 1. Continuous Heartbeat LED blink: Toggles every 500 ms (1 Hz pulse)
  static unsigned long lastBlinkMs = 0;
  if (millis() - lastBlinkMs >= 500) {
    lastBlinkMs = millis();
    digitalWrite(PIN_STATUS_LED, !digitalRead(PIN_STATUS_LED));
  }

  // 2. Deterministic 250 Hz sampling (every 4000 µs)
  if (currentMicros - lastSampleMicros >= SAMPLE_INTERVAL_MICROS) {
    lastSampleMicros += SAMPLE_INTERVAL_MICROS;

    // Read AD8232 analog voltage on A0
    uint16_t adcVal = analogRead(PIN_ECG_ANALOG);

    // Read Lead-Off detection pins
    uint8_t loP = (digitalRead(PIN_LEAD_OFF_P) == HIGH) ? 1 : 0;
    uint8_t loN = (digitalRead(PIN_LEAD_OFF_N) == HIGH) ? 1 : 0;

    // Store in batch buffer
    sampleBuffer[bufferIndex].adc = adcVal;
    sampleBuffer[bufferIndex].lo_plus = loP;
    sampleBuffer[bufferIndex].lo_minus = loN;
    bufferIndex++;

    // Print to USB Serial for Serial Plotter / Monitor (ADC, LO+, LO-)
    Serial.printf("%u,%u,%u\n", adcVal, loP * 1023, loN * 1023);

    // When batch buffer is full, transmit over UDP
    if (bufferIndex >= BATCH_SIZE) {
      if (WiFi.status() == WL_CONNECTED) {
        sendUdpBatch();
      }
      bufferIndex = 0;
    }
  }

  // Yield to ESP8266 background Wi-Fi housekeeping
  yield();
}

void sendUdpBatch() {
  packetSequence++;

  // Construct compact JSON payload
  // e.g.: {"seq":1,"ts":12345,"s":[[512,0,0],[515,0,0],...]}
  char packet[512];
  int offset = snprintf(packet, sizeof(packet),
    "{\"seq\":%u,\"ts\":%lu,\"s\":[",
    packetSequence, millis()
  );

  for (int i = 0; i < BATCH_SIZE; i++) {
    offset += snprintf(packet + offset, sizeof(packet) - offset,
      "[%u,%u,%u]%s",
      sampleBuffer[i].adc,
      sampleBuffer[i].lo_plus,
      sampleBuffer[i].lo_minus,
      (i == BATCH_SIZE - 1) ? "" : ","
    );
  }

  snprintf(packet + offset, sizeof(packet) - offset, "]}");

  udp.beginPacket(TARGET_HOST_IP, UDP_PORT);
  udp.write(packet);
  udp.endPacket();
}
