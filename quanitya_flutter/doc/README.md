# Quanitya Documentation

## Architecture

- [ARCHITECTURE.md](ARCHITECTURE.md) - Main architecture diagrams and overview

## API Documentation

Generate API docs with:

```bash
dart doc .
```

Output will be in `doc/api/`. Open `doc/api/index.html` in a browser.

## Development Guides

Located in `.kiro/steering/`:

| Guide | Purpose |
|-------|---------|
| `quanitya_development_standards.md` | Freezed, Drift, Cubits, Injectable patterns |
| `cubit_ui_flow_pattern.md` | Automatic UI feedback (State → Toast) |
| `flutter_color_palette_guide.md` | Enumerated color system with auto dark mode |
| `pii-less.md` | E2EE dual DAO architecture |

## Legacy Documentation

The `md/` folder contains historical design documents and planning notes. These may be outdated - refer to `doc/` for current architecture.

## Quick Links

| Topic | File |
|-------|------|
| Template Pipeline | [ARCHITECTURE.md#template-generation-pipeline](ARCHITECTURE.md#template-generation-pipeline) |
| E2EE Data Flow | [ARCHITECTURE.md#data-flow-pii-less-e2ee](ARCHITECTURE.md#data-flow-pii-less-e2ee) |
| UI Guide | [../ui-guide.md](../ui-guide.md) |
| Repo Status | [../REPO_STATUS.md](../REPO_STATUS.md) |
