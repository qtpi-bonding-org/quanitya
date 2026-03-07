# Contributing to Quanitya

Thanks for your interest in contributing! This guide will help you get started.

## Contributor License Agreement

Before your first contribution can be merged, you must sign the [Contributor License Agreement](CLA.md). This is required because Quanitya is licensed under BSL 1.1, and we need the ability to manage licensing across the project.

When you open your first PR, the CLA Assistant bot will comment with a link to sign. It's a one-time process.

## Getting Started

1. Fork the repository
2. Clone your fork
3. Follow the setup instructions in the [README](README.md)
4. Create a feature branch from `main`

## Development Setup

```bash
# Backend
cd quanitya_serverpod/quanitya_server
cp .env.example .env
docker compose up -d
dart bin/main.dart --apply-migrations

# Flutter app
cd quanitya_flutter
cp .env.example .env
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Code Standards

- Follow the patterns in `.kiro/steering/` — these are the project's development standards
- Use Freezed for immutable state classes
- Use the Cubit + UiFlow pattern for state management
- Use the Dual DAO pattern for data that syncs
- Use Injectable for dependency injection
- Use semantic design tokens (see `ui_design_guide.md`) — no hardcoded colors, sizes, or padding

## Pull Request Process

1. Create a feature branch: `git checkout -b feat/my-feature`
2. Make your changes
3. Run analysis: `flutter analyze` (no errors allowed)
4. Run tests: `flutter test`
5. Run code generation if you changed models: `dart run build_runner build --delete-conflicting-outputs`
6. Commit with a clear message following conventional commits:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `chore:` for maintenance
   - `refactor:` for code restructuring
7. Push and open a PR against `main`

## What to Contribute

- Bug fixes
- Documentation improvements
- New widget types for the template system
- Integration adapters (health, fitness, etc.)
- Localization / translations
- Test coverage improvements

## What Not to Change

- Don't modify generated files (`*.freezed.dart`, `*.g.dart`, protocol files)
- Don't change the E2EE architecture without discussion
- Don't add dependencies without justification

## Reporting Issues

Use GitHub Issues. Include:
- Steps to reproduce
- Expected vs actual behavior
- Platform and version info
- Screenshots if UI-related

## Questions?

Open a discussion on GitHub or file an issue tagged `question`.
