// Proximity LED Control - LOW LATENCY VERSION
// Optimized for faster response

const int TRIG_PIN = 9;
const int ECHO_PIN = 10;
const int LED_PIN = 13;

// Pre-calculate constants for speed
const float SOUND_SPEED_CM_PER_US = 0.034;
const int MAX_DISTANCE = 400;
const int MIN_DISTANCE = 2;
const int MAX_USEFUL_DISTANCE = 100;

int distance;
int targetBrightness;
int currentBrightness = 0;

void setup() {
  // Faster serial for debugging (optional - can remove for speed)
  Serial.begin(115200); // Increased from 9600 for faster debug
  
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  
  Serial.println("Low Latency Proximity Control");
}

void loop() {
  // === OPTIMIZED DISTANCE READING ===
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);  // KEEP AT 10µs - REQUIRED!
  digitalWrite(TRIG_PIN, LOW);
  
  // pulseIn has timeout - use shorter timeout for faster response
  // Default timeout is ~38ms, we reduce to 10ms
  unsigned long duration = pulseIn(ECHO_PIN, HIGH, 10000); // 10ms timeout
  
  // Fast distance calculation (avoid float if possible)
  if (duration == 0) {
    distance = MAX_USEFUL_DISTANCE; // No echo = far
  } else {
    distance = (duration * 34) / 2000; // Integer math: (duration * 0.034) / 2
  }
  
  // === FAST BRIGHTNESS MAPPING ===
  // Clamp distance
  if (distance < MIN_DISTANCE) distance = MIN_DISTANCE;
  if (distance > MAX_USEFUL_DISTANCE) distance = MAX_USEFUL_DISTANCE;
  
  // Direct mapping without map() function overhead
  // brightness = 255 - ((distance - 2) * 255 / 98)
  targetBrightness = 255 - ((distance - MIN_DISTANCE) * 255 / (MAX_USEFUL_DISTANCE - MIN_DISTANCE));
  
  // === IMMEDIATE RESPONSE (no smoothing) ===
  analogWrite(LED_PIN, targetBrightness);
  currentBrightness = targetBrightness;
  
  // Optional: minimal smoothing
  // analogWrite(LED_PIN, (currentBrightness * 7 + targetBrightness * 3) / 10);
  // currentBrightness = (currentBrightness * 7 + targetBrightness * 3) / 10;
  
  // Debug (comment this out for absolute max speed)
  if (millis() % 100 < 50) { // Print less frequently
    Serial.print(distance);
    Serial.print("cm | ");
    Serial.println(targetBrightness);
  }
  
  // Minimal delay - as low as 10ms for faster updates
  delay(10); // Reduce from 50ms to 10ms
}
