// Proximity LED + Active Buzzer Control - LOW LATENCY VERSION
// LED on pin 13 (proportional brightness)
// Active buzzer on pin 6 (proportional "volume" via PWM, direct-drive)
// Note: active buzzers have their own internal oscillator, so PWM doesn't
// give perfectly clean linear volume control the way LED PWM gives brightness -
// but reducing average voltage does noticeably quiet most active buzzers,
// giving a workable louder-when-closer effect.
//
// BUZZER WIRING (direct drive - active buzzers draw low current, safe direct):
//   Buzzer positive lead -> Arduino pin 6
//   Buzzer negative lead -> Arduino GND

const int TRIG_PIN = 9;
const int ECHO_PIN = 10;
const int LED_PIN = 13;
const int BUZZER_PIN = 6;

// Pre-calculate constants for speed
const float SOUND_SPEED_CM_PER_US = 0.034;
const int MAX_DISTANCE = 400;
const int MIN_DISTANCE = 2;
const int MAX_USEFUL_DISTANCE = 100;

int distance;
int targetBrightness;
int buzzerVolume;

void setup() {
  Serial.begin(115200);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  Serial.println("Proximity LED + Buzzer (proportional volume) Control");
}

void loop() {
  // === DISTANCE READING ===
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);  // KEEP AT 10µs - REQUIRED!
  digitalWrite(TRIG_PIN, LOW);

  unsigned long duration = pulseIn(ECHO_PIN, HIGH, 10000); // 10ms timeout

  if (duration == 0) {
    distance = MAX_USEFUL_DISTANCE; // No echo = far
  } else {
    distance = (duration * 34) / 2000; // Integer math: (duration * 0.034) / 2
  }

  // Clamp distance
  if (distance < MIN_DISTANCE) distance = MIN_DISTANCE;
  if (distance > MAX_USEFUL_DISTANCE) distance = MAX_USEFUL_DISTANCE;

  // === LED: proportional brightness ===
  targetBrightness = 255 - ((distance - MIN_DISTANCE) * 255 / (MAX_USEFUL_DISTANCE - MIN_DISTANCE));
  analogWrite(LED_PIN, targetBrightness);

  // === BUZZER: proportional volume via PWM - louder as object gets closer ===
  buzzerVolume = targetBrightness; // same 0-255 mapping as LED brightness
  analogWrite(BUZZER_PIN, buzzerVolume);

  // Debug
  if (millis() % 100 < 50) {
    Serial.print(distance);
    Serial.print("cm | LED: ");
    Serial.print(targetBrightness);
    Serial.print(" | Buzzer volume: ");
    Serial.println(buzzerVolume);
  }

  delay(10);
}
