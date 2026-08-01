# esp8266@us_sensor_firmware

## Setup
1. Copy `.env.example` to `.env` and configure your port
2. Run `pnpm install`

## Commands
```bash
# Build
pnpm run arduino:compile --fqbn=arduino:avr:uno

# Upload
pnpm run arduino:upload --port=/dev/ttyACM0 --fqbn=arduino:avr:uno

# Monitor
pnpm run arduino:monitor --port=/dev/ttyACM0

# Clean
pnpm run arduino:clean
```
