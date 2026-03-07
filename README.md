# Quanitya

[![License: BSL 1.1](https://img.shields.io/badge/License-BSL_1.1-blue.svg)](LICENSE)

**Quanitya** is an End-to-End Encrypted (E2EE) *qua*ntitative and *qua*litative self-tracking app, built with Flutter, powered by Serverpod, and featuring offline-first synchronization via PowerSync.

The name is a portmanteau blending **Qua-** (Quantitative/Qualitative tracking) and **Anitya** (Sanskrit for Impermanence).

## Pronunciation

> **"Kwah-NIT-yuh"** — IPA: /kwɑˈnɪtjə/

---

## The Philosophy: Data as Analytical Mindfulness

The application is founded on the idea that objective data and subjective insight are two sides of the same coin, providing an analytical path to mindfulness.

**Data as an Analytical Path to Mindfulness** — For those struggling with low interoception — the ability to *feel* internal states — traditional mindfulness practices can be frustrating. Quanitya acts as an external mirror, providing a measurable anchor for internal observation. By tracking anything and everything — from emotion and thought to weight and sleep — you build a comprehensive, externalized map of your internal world. The app provides **neutral and useful insights**, not judgmental commands.

**Observing Impermanence (Anitya)** — Every historical log, chart, and journal entry serves as a constant, gentle reminder that things are transient. Your happiness is transient, your sadness is transient, and every metric is temporary. By observing the constant flow of data, you are encouraged to stay present, be grateful for positive states while they last, and use historical data to cultivate insight.

---

## Features

### Privacy & Security
- **End-to-End Encryption** — AES-256-GCM for data, RSA-OAEP for keys, ECDSA P-256 for authentication
- **Zero-Knowledge Architecture** — Server never sees plaintext data or private keys
- **Anonymous Authentication** — ECDSA P-256 public key auth with challenge-response
- **Device Management** — Register, list, and revoke devices with audit trail
- **Account Recovery** — Ultimate key backup system for account restoration
- **Biometric & PIN Protection** — Local authentication for app access

### Data Tracking & Templates
- **Custom Templates** — Create tracking templates with 7 field types:
  - Integer, Float, Dimension (SI units), Boolean, Enumerated, Text, DateTime, Reference
- **AI Template Generation** — Describe what you want to track and an LLM generates a structured form template with themed styling
- **BYOK** — Bring your own API key for AI features (OpenRouter, Gemini)
- **Instant Logging** — Quick entry from template cards
- **Bulk Operations** — Hide, archive, and manage multiple templates

### Visualization & Analytics
- **5 Chart Types**: Time Series, Boolean Heatmap, Categorical Scatter, Multi-Series Overlay, Contribution Heatmap
- **Statistical Analysis** — 40+ calculation operations (descriptive stats, frequency analysis, temporal analysis, categorical analysis)
- **JavaScript Analysis Pipeline** — Custom analysis logic using JavaScript with WASM execution in a sandboxed runtime
- **AI-Powered Suggestions** — Generate analysis scripts from natural language intent
- **Pipeline Builder** — Visual interface for creating, testing, and saving analysis workflows

### Sync & Offline Support
- **Offline-first** — Full functionality without internet via local SQLite
- **PowerSync Integration** — Background sync with PostgreSQL
- **Cross-Device Sync** — Encrypted data synchronization across devices
- **Privacy-Preserving Analytics** — Usage events are stored locally in an inbox. Users control when (or if) they are sent.

### Scheduling & Automation
- **RRULE Schedules** — Recurring reminders with RFC 5545 compliance
- **Flexible Patterns** — Daily, weekly, monthly, custom intervals
- **Local Notifications** — Reminder notifications for scheduled tracking

### User Experience
- **Dark/Light Themes** — Adaptive UI with system theme support
- **Zen Design System** — Clean, minimalist interface
- **Cross-Platform** — iOS, Android, and Web via Flutter
- **Accessibility** — Screen reader support and keyboard navigation
- **Localization** — Multi-language support

### Data Management
- **Import/Export** — Full JSON data export for backup and migration
- **Data Validation** — Type-safe field validation with error handling
- **Search & Filter** — Find templates and entries quickly

---

## Project Structure

```
quanitya_flutter/          Flutter app (iOS, Android, Web)
quanitya_serverpod/        Community Serverpod backend
  quanitya_server/           Server (sync, storage quotas, E2EE data)
  quanitya_client/           Generated client library
quanitya_cloud_client/     Generated client for the cloud server
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.38.5
- Dart SDK ^3.10.0
- Docker & Docker Compose (for backend services)
- Serverpod CLI (`dart pub global activate serverpod_cli`)

### 1. Clone and set up dependencies

```bash
git clone https://github.com/qtpi-bonding-org/quanitya.git
cd quanitya
```

### 2. Start backend services

```bash
cd quanitya_serverpod/quanitya_server

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your passwords

# Start Postgres, Redis, and PowerSync
docker compose up -d

# Set up PowerSync replication role
psql -h localhost -p 8090 -U postgres -d quanitya \
  -v powersync_password='your_password' \
  -f powersync_setup.sql

# Create Serverpod passwords file
# See config/passwords.yaml section in Serverpod docs

# Apply database migrations
dart bin/main.dart --apply-migrations
```

### 3. Configure the Flutter app

```bash
cd quanitya_flutter

# Copy environment template
cp .env.example .env
# Edit .env with your server URLs and API keys

# Get dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Architecture

Quanitya uses a dual-table architecture for privacy:

- **Local tables** store plaintext data on-device for the UI
- **Encrypted shadow tables** store E2EE ciphertext that syncs to the server
- Writes are transactional — both tables update atomically via Dual DAOs

### Tech Stack

| Layer | Technology |
|-------|-----------|
| App | Flutter, Dart |
| State | flutter_bloc / Cubits |
| Local DB | Drift (SQLite) |
| Sync | PowerSync |
| Backend | Serverpod |
| Server DB | PostgreSQL |
| Cache | Redis |
| AI | OpenRouter, Gemini (BYOK) |

## Development

### Code generation

```bash
# Serverpod (run from project root)
serverpod generate

# Flutter (run from quanitya_flutter/)
dart run build_runner build --delete-conflicting-outputs
```

### Running tests

```bash
# Flutter tests
cd quanitya_flutter
flutter test

# Server tests (requires running database)
cd quanitya_serverpod/quanitya_server
dart test
```

### Development standards

See `quanitya_flutter/.kiro/steering/` for:
- `quanitya_development_standards.md` — Freezed, Drift, Cubits, Injectable patterns
- `cubit_ui_flow_pattern.md` — Automatic UI feedback system
- `pii-less.md` — E2EE architecture details
- `ui_design_guide.md` — Design system tokens and patterns

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, code standards, and the PR process.

## Security

See [SECURITY.md](SECURITY.md) for our vulnerability reporting policy.

## License

This project is licensed under the [Business Source License 1.1](LICENSE) with a 5-year conversion to Apache 2.0. See the LICENSE file for details.
