# Quanitya Serverpod

Community Serverpod backend for Quanitya. Handles E2EE data sync, storage quotas, and PowerSync integration.

## Structure

```
quanitya_server/    Server application
quanitya_client/    Generated client library (auto-generated, do not edit)
```

## Setup

### Prerequisites

- Dart SDK ^3.10.0
- Docker & Docker Compose
- Serverpod CLI: `dart pub global activate serverpod_cli`

### Quick Start

```bash
cd quanitya_server

# Copy and configure environment
cp .env.example .env

# Start database and cache
docker compose up -d postgres redis

# Create config/passwords.yaml with your database password
# See Serverpod docs: https://docs.serverpod.dev

# Apply migrations
dart bin/main.dart --apply-migrations

# Start the server
dart bin/main.dart
```

### PowerSync Setup

PowerSync provides real-time sync between the server database and client devices.

```bash
# Set up the replication role (after Postgres is running)
psql -h localhost -p 8090 -U postgres -d quanitya \
  -v powersync_password='your_password' \
  -f powersync_setup.sql

# Start PowerSync
docker compose up -d powersync
```

## Code Generation

```bash
serverpod generate
```

This regenerates the protocol and client library from `.spy.yaml` model definitions.

## Endpoints

| Endpoint | Purpose |
|----------|---------|
| `SyncEndpoint` | CRUD for E2EE encrypted data (templates, entries, schedules, pipelines) |
| `TemplateAesthetics` | Non-encrypted template styling (themes, colors, fonts) |
| `StorageUsage` | Per-account storage quota tracking |
