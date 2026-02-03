# Analysis Pipeline Architecture

## Quick Reference

### When to Use What

**For Cubits and UI (Recommended):**
```dart
final orchestrator = getIt<AnalysisOrchestrator>();
```

**For Advanced/Internal Use:**
```dart
final engine = getIt<AnalysisEngine>();
final streaming = getIt<StreamingAnalyticsService>();
final wasm = getIt<IWasmAnalysisService>();
```

## Service Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                  AnalysisOrchestrator                        │
│                  (Unified API Facade)                        │
│                                                              │
│  • executeById(pipelineId)                                  │
│  • execute(pipeline)                                        │
│  • streamScalarResults(pipelineId)                          │
│  • streamLivePreview(...)                                   │
└──────────────┬──────────────────────┬───────────────────────┘
               │                      │
               │                      │
       ┌───────▼────────┐    ┌────────▼──────────────────────┐
       │ AnalysisEngine │    │ StreamingAnalyticsService     │
       │                │    │                               │
       │ • execute()    │    │ • streamScalarResults()       │
       │ • MVS convert  │    │ • streamLivePreview()         │
       └───────┬────────┘    │ • Watch pipeline changes      │
               │             │ • Watch data changes          │
               │             └───────────────────────────────┘
               │
       ┌───────▼──────────────────────────────────────────────┐
       │           WasmAnalysisService                        │
       │                                                      │
       │ 1. Fetch data from database                         │
       │ 2. Load mvs_shell.js.j2 template                    │
       │ 3. Render with Jinja2 (inject data)                 │
       │ 4. Execute in background isolate                    │
       │ 5. Box results into AnalysisOutput                  │
       └──────────────────────────────────────────────────────┘
```

## Data Flow

### Execute Pipeline Once

```
UI/Cubit
   │
   │ orchestrator.executeById('pipeline-123')
   │
   ▼
AnalysisOrchestrator
   │
   │ _pipelineRepo.getPipeline(id)
   │ _engine.execute(pipeline)
   │
   ▼
AnalysisEngine
   │
   │ _wasmService.execute(pipeline)
   │
   ▼
WasmAnalysisService
   │
   │ 1. _fetchFieldData(fieldId)
   │ 2. Load template & libraries
   │ 3. Isolate.run(_executeInIsolate)
   │ 4. _boxResult(rawJson)
   │
   ▼
AnalysisOutput (Scalar/Vector/Matrix)
```

### Stream Real-Time Results

```
UI/Cubit
   │
   │ orchestrator.streamScalarResults('pipeline-123')
   │
   ▼
AnalysisOrchestrator
   │
   │ _streamingService.streamScalarResults(id)
   │
   ▼
StreamingAnalyticsService
   │
   │ Watch: _pipelineRepo.watchAllPipelines()
   │ Watch: _streamTemplateData(templateId)
   │
   │ On change:
   │   _analysisEngine.execute(pipeline)
   │   Extract scalars from result
   │
   ▼
Stream<Map<String, double>>
```

## File Locations

### Core Services
```
lib/logic/analytics/services/
├── analysis_orchestrator.dart          # Unified API (USE THIS)
├── analysis_engine.dart                # Core execution
├── streaming_analytics_service.dart    # Real-time streaming
├── wasm_analysis_service.dart          # Low-level JS execution
└── pipeline_executor.dart              # Legacy visual pipelines
```

### Models
```
lib/logic/analytics/models/
├── analysis_pipeline.dart              # Pipeline definition
├── analysis_output.dart                # Typed output (Scalar/Vector/Matrix)
└── matrix_vector_scalar/               # MVS type system
    ├── mvs_union.dart
    ├── time_series_matrix.dart
    ├── value_vector.dart
    └── ...
```

### Template
```
assets/scripts/
└── mvs_shell.js.j2                     # Jinja2 template (well-documented)
```

### Documentation
```
lib/logic/analytics/
├── README.md                           # Complete guide
├── ARCHITECTURE.md                     # This file (quick reference)
└── REFACTORING_SUMMARY.md             # What changed and why
```

## Responsibilities Matrix

| Service | Execute | Stream | MVS Convert | JS Execution | Data Fetch |
|---------|---------|--------|-------------|--------------|------------|
| **AnalysisOrchestrator** | ✅ (delegates) | ✅ (delegates) | ❌ | ❌ | ❌ |
| **AnalysisEngine** | ✅ | ❌ | ✅ | ❌ (delegates) | ❌ |
| **StreamingAnalyticsService** | ❌ (uses engine) | ✅ | ❌ | ❌ | ❌ |
| **WasmAnalysisService** | ✅ (low-level) | ❌ | ❌ | ✅ | ✅ |

## Common Patterns

### Pattern 1: Execute Once
```dart
final orchestrator = getIt<AnalysisOrchestrator>();
final result = await orchestrator.executeById('pipeline-123');

result.when(
  scalar: (scalars) => print('Mean: ${scalars.first.value}'),
  vector: (vectors) => showChart(vectors.first),
  matrix: (matrices) => showTable(matrices.first),
);
```

### Pattern 2: Stream Dashboard KPIs
```dart
final orchestrator = getIt<AnalysisOrchestrator>();

orchestrator.streamScalarResults('pipeline-123').listen((kpis) {
  // kpis = {'Mean': 75.2, 'Max': 100.0}
  emit(state.copyWith(kpis: kpis));
});
```

### Pattern 3: Live Preview in Builder
```dart
final orchestrator = getIt<AnalysisOrchestrator>();

orchestrator.streamLivePreview(
  scriptJs: 'return ss.mean(data.values);',
  fieldId: 'template-1:mood',
  outputMode: AnalysisOutputMode.scalar,
  shell: AnalysisShell.mvsWasm,
).listen((output) {
  emit(state.copyWith(liveResult: output));
});
```

## Error Handling

All services use `tryMethod` pattern:

```dart
Future<AnalysisOutput> execute(AnalysisPipelineModel pipeline) {
  return tryMethod(
    () => _wasmService.execute(pipeline),
    AnalysisException.new,
    'execute',
  );
}
```

Errors bubble up as `AnalysisException` with context.

## Testing Strategy

### Unit Tests
- **AnalysisOrchestrator** - Mock engine and streaming service
- **AnalysisEngine** - Mock WASM service
- **StreamingAnalyticsService** - Mock repository and engine
- **WasmAnalysisService** - Test JS execution with sample scripts

### Integration Tests
- End-to-end pipeline execution
- Database integration
- Streaming behavior

## Related Documentation

- [Complete Guide](README.md) - Full architecture documentation
- [MVS System](models/matrix_vector_scalar/README.md) - Type system details
- [Refactoring Summary](REFACTORING_SUMMARY.md) - What changed and why
