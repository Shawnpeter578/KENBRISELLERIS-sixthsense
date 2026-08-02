Here is your architecture compressed into a clean, machine-readable semantic spec:

---

## SYSTEM ARCHITECTURE: Blind Smart Stick Data Pipeline

### COMPONENTS

| Component | Role | Configuration |
|-----------|------|---------------|
| **ESP8266** | Edge device (sensor node) | Hardcoded WiFi SSID/PSK, hardcoded user ID, hardcoded backend endpoint URL |
| **Sensors** | Ultrasonic (distance), optional GPS/IMU | Polled every 2-5 seconds |
| **Backend Server** | Flask/FastAPI (Python) | REST endpoint `/log`, in-memory or SQLite storage, simple rule-based inference engine |
| **Frontend Dashboard** | Static HTML/JS | Fetches data from server via user ID, displays graphs and predictions |

---

### DATA FLOW (Synchronous, One-Way + ACK)

```
[ESP8266] 
    → read sensors 
    → build GET request: 
        /log?user={HARDCODED_ID}&dist={cm}&lat={x}&lng={y}
    → HTTP over WiFi (port 5000)
    → [BACKEND SERVER]
        → parse query params
        → store to in-memory list (timestamped)
        → run inference: if dist < 30cm → prediction = "STOP"
        → return prediction as plaintext response
    → [ESP8266]
        → read response body
        → if "STOP" → activate buzzer/vibration motor
        → else → silent
    → sleep 3s → repeat
```

---

### SECURITY MODEL (Hackathon Scope)

| Layer | Method |
|-------|--------|
| Device authentication | Hardcoded `user_id` sent in every request |
| Data in transit | HTTP (plaintext) – HTTPS skipped to save RAM/Flash |
| Access control | Server filters data by `user_id`; frontend fetches only own ID |
| Production note | Hardcoded values replaced with TLS + token-based auth post-hackathon |

---

### INFERENCE ENGINE (MVP)

- **Type**: Rule-based (no ML training required)
- **Input**: Sliding window of last 5 distance readings
- **Logic**:
  - if any reading < 30cm → `"OBSTACLE IMMINENT"`
  - if average < 60cm over 5 readings → `"NARROW PASSAGE"`
  - else → `"CLEAR PATH"`
- **Output**: String returned in HTTP response body

---

### DEPLOYMENT

| Component | Environment |
|-----------|-------------|
| Backend | Local laptop (192.168.x.x) or ngrok tunnel for external access |
| Frontend | Local static HTML, fetches from backend |
| ESP8266 | Venue WiFi or mobile hotspot |
| Database | None (RAM list) for demo; SQLite for persistence if needed |

---

### JUDGE PITCH (One-Liner)

> *"WiFi-only smart stick with hardcoded device ID pushes real-time sensor data to a local server, where a lightweight inference engine detects obstacles and sends haptic feedback — all without SIM, Bluetooth, or cloud dependencies."*

---

**Keywords for searchability:** `ESP8266`, `HTTP REST`, `Flask`, `IoT telemetry`, `hardcoded credentials`, `rule-based inference`, `haptic feedback`, `hackathon MVP`
