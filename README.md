# Quanitya

Privacy-first personal tracking app with end-to-end encryption, AI-generated templates, and offline-first sync.

## What is Quanitya?

Quanitya lets you track anything — habits, health metrics, moods, workouts, or custom data — using AI-generated form templates. All personal data is end-to-end encrypted on your device before syncing. The server never sees plaintext PII.

### Key Features

- **E2EE by default** — All user data is encrypted on-device before sync. The server stores only ciphertext.
- **AI template generation** — Describe what you want to track and an LLM generates a structured form template with themed styling.
- **Offline-first** — Full functionality without internet. Sync happens in the background via PowerSync.
- **Privacy-preserving analytics** — Usage events are stored locally in an inbox. Users control when (or if) they are sent.
- **Cross-platform** — Flutter app for iOS, Android, and web.
- **BYOK** — Bring your own API key for AI features (OpenRouter, Gemini).

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

See [quanitya_flutter/doc/ARCHITECTURE.md](quanitya_flutter/doc/ARCHITECTURE.md) for detailed diagrams.

### Tech Stack

| Layer | Technology |
|-------|-----------|
| App | Flutter, Dart |
| State | flutter_bloc / Cubits |
| Local DB | Drift (SQLite) |
| Sync | PowerSync |
| Backend | Serverpod |
| Server DB | PostgreSQL (pgvector) |
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
