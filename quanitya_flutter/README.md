# Quanitya Flutter App

Cross-platform Flutter app for Quanitya — a privacy-first personal tracker with E2EE and AI-generated templates.

## Setup

```bash
# Install dependencies
flutter pub get

# Copy environment config
cp .env.example .env
# Edit .env with your server URLs and optional API keys

# Run code generation (Freezed, Drift, Injectable, etc.)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Project Structure

```
lib/
  app/              App bootstrap, modules, DI setup
  data/             Database (Drift), DAOs, repositories, sync
  design_system/    Reusable widgets, theme tokens, primitives
  features/         Feature modules (templates, analytics, settings, ...)
  infrastructure/   Auth, crypto, LLM, platform services
  logic/            Business logic (calculations, templates, analytics)
  integrations/     External integrations (health, etc.)
```

## Key Patterns

- **Cubit + UiFlow** — State management with automatic snackbar/dialog feedback
- **Dual DAO** — Transactional writes to local + encrypted shadow tables
- **Repository + tryMethod** — Consistent error handling across data layer
- **Injectable** — Compile-time dependency injection via GetIt

## Tests

```bash
flutter test
```

## Documentation

- [Architecture](doc/ARCHITECTURE.md) — System diagrams and data flow
- [Development Standards](.kiro/steering/quanitya_development_standards.md)
- [E2EE Architecture](.kiro/steering/pii-less.md)
- [UI Design Guide](.kiro/steering/ui_design_guide.md)
