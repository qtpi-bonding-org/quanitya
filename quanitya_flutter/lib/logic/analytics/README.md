# JavaScript Analysis Pipeline - Architecture Guide

## Overview

The JavaScript Analysis Pipeline enables AI-powered data analysis using custom JavaScript logic executed in a sandboxed WASM environment. It supports three output modes: **Scalar** (single values), **Vector** (time series), and **Matrix** (multi-dimensional data).

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI Layer                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │ Dashboard Cards  │  │ Pipeline Builder │  │ Chart Viewers │ │
│  │  (Scalar KPIs)   │  │  (Live Preview)  │  │ (Vector/Matrix)│ │
│  └────────┬─────────┘  └────────┬─────────┘  └───────┬───────┘ │
└───────────┼────────────────────┼────────────────────┼──────────┘
            │                    │                    │
            │ streamScalarResults│ streamLivePreview  │ execute
            │                    │                    │
┌───────────▼────────────────────▼────────────────────▼──────────┐
│                   AnalysisOrchestrator                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ • Unified API for all analysis operations                │  │
│  │ • Coordinates AnalysisEngine + StreamingAnalyticsService │  │
│  │ • Simplifies consumer code (Cubits, UI)                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────┬─────────────────────┬───────────────────────────────┘
            │                     │
            │ execute()           │ streamScalarResults()
            │                     │ streamLivePreview()
            │                     │
┌───────────▼─────────┐  ┌────────▼──────────────────────────────┐
│   AnalysisEngine    │  │  StreamingAnalyticsService            │
│  ┌───────────────┐  │  │  ┌─────────────────────────────────┐ │
│  │ • Execute     │  │  │  │ • Watch pipeline changes        │ │
│  │   pipelines   │  │  │  │ • Watch data changes            │ │
│  │ • MVS type    │  │  │  │ • Stream real-time results      │ │
│  │   conversion  │  │  │  │ • Extract scalar summaries      │ │
│  └───────┬───────┘  │  │  └─────────────────────────────────┘ │
└──────────┼──────────┘  └─────────────────────────────────────────┘
           │
           │ execute(pipeline)
           │
┌──────────▼──────────────────────────────────────────────────────┐
│                   WasmAnalysisService                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. Fetch field data from database (90-day window)       │  │
│  │ 2. Load mvs_shell.js.j2 template                        │  │
│  │ 3. Render template with Jinja2 (inject data)            │  │
│  │ 4. Execute in background isolate                        │  │
│  │ 5. Box results into typed AnalysisOutput               │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────┬─────────────────────────────────────────────────────┘
            │
            │ Isolate.run(_executeInIsolate)
            │
┌───────────▼─────────────────────────────────────────────────────┐
│              JavaScript Execution (Background Isolate)           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. Initialize flutter_js runtime                        │  │
│  │ 2. Load simple-statistics library                       │  │
│  │ 3. Execute rendered script (template + user logic)      │  │
│  │ 4. Return JSON result {status, result}                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Service Responsibilities

### AnalysisOrchestrator
**Purpose:** Unified API facade for consumers

- Simplifies API surface for Cubits and UI
- Delegates to specialized services
- Provides clear, purpose-driven methods
- No business logic - pure coordination

### AnalysisEngine
**Purpose:** Core execution and type conversion

- Executes pipelines via WasmAnalysisService
- Converts AnalysisOutput to legacy MVS types
- Maintains backward compatibility

### StreamingAnalyticsService
**Purpose:** Real-time result streaming

- Watches pipeline definition changes
- Watches template data changes
- Streams results on any change
- Extracts scalar summaries for dashboards

### WasmAnalysisService
**Purpose:** Low-level JavaScript execution

- Fetches data from database
- Renders Jinja2 templates
- Executes JavaScript in isolate
- Boxes raw results into typed outputs

## Core Components

### 1. AnalysisOrchestrator
**Location:** `services/analysis_orchestrator.dart`

Unified API facade that simplifies interaction with the analysis system. Coordinates specialized services without containing business logic.

**Responsibilities:**
- Provide clear, purpose-driven API methods
- Delegate to AnalysisEngine and StreamingAnalyticsService
- Load pipelines from repository
- Simplify consumer code (Cubits, UI)

**Key Methods:**
```dart
// Execute a saved pipeline
Future<AnalysisOutput> executeById(String pipelineId)

// Execute a pipeline model directly
Future<AnalysisOutput> execute(AnalysisPipelineModel pipeline)

// Stream scalar KPIs for dashboard (delegates to StreamingAnalyticsService)
Stream<Map<String, double>> streamScalarResults(String pipelineId)

// Stream live preview for builder (delegates to StreamingAnalyticsService)
Stream<AnalysisOutput> streamLivePreview({
  required String scriptJs,
  required String fieldId,
  required AnalysisOutputMode outputMode,
  required AnalysisShell shell,
})
```

### 2. AnalysisEngine
**Location:** `services/analysis_engine.dart`

Core execution engine that delegates to WasmAnalysisService and provides MVS type conversions.

**Responsibilities:**
- Execute pipelines via WasmAnalysisService
- Convert AnalysisOutput to legacy MvsUnion types
- Maintain backward compatibility with old MVS system

**Key Methods:**
```dart
Future<AnalysisOutput> execute(AnalysisPipelineModel pipeline)
Future<Map<String, MvsUnion>> executePipelineWithContext(AnalysisPipelineModel pipeline)
```

### 3. StreamingAnalyticsService
**Location:** `services/streaming_analytics_service.dart`

Real-time streaming service that watches for changes and emits updated results.

**Responsibilities:**
- Watch pipeline definition changes
- Watch template data changes (log entries)
- Stream results on any change
- Extract scalar summaries for dashboard display

**Key Methods:**
```dart
Stream<Map<String, double>> streamScalarResults(String pipelineId)
Stream<AnalysisOutput> streamResultsForLivePreview({...})
```
**Location:** `services/wasm_analysis_service.dart`

### 4. WasmAnalysisService
**Location:** `services/wasm_analysis_service.dart`

Low-level JavaScript execution engine. Handles data fetching, template rendering, and isolate execution.

**Execution Flow:**
1. **Data Fetching** - Queries database for field data (90-day window)
2. **Asset Loading** - Loads `mvs_shell.js.j2` template and `simple_statistics.js`
3. **Template Rendering** - Uses Jinja2 to inject data into template
4. **Isolate Execution** - Runs JavaScript in background thread
5. **Result Boxing** - Converts raw JSON to typed `AnalysisOutput`

**Key Methods:**
```dart
Future<AnalysisOutput> execute(AnalysisPipelineModel pipeline)
```

## Data Models

### AnalysisPipelineModel
**Location:** `models/analysis_pipeline.dart`

Defines a complete analysis pipeline configuration.

```dart
@freezed
class AnalysisPipelineModel {
  String id;              // Unique identifier
  String name;            // Display name
  String fieldId;         // Format: "templateId:fieldName"
  AnalysisOutputMode outputMode;  // scalar | vector | matrix
  AnalysisShell shell;    // mvs_wasm (currently only option)
  String scriptJs;        // User's JavaScript logic
  String? reasoning;      // AI-generated explanation
  String? displayConfigJson;  // UI rendering hints
  DateTime updatedAt;     // Last modified timestamp
}
```

### AnalysisOutput
**Location:** `models/analysis_output.dart`

Type-safe union for analysis results. Enforces output mode contract.

```dart
@freezed
class AnalysisOutput {
  // Single values (e.g., Mean=75.2, Max=100)
  const factory AnalysisOutput.scalar(List<AnalysisScalar> scalars);
  
  // Time series (e.g., Daily averages over 30 days)
  const factory AnalysisOutput.vector(List<AnalysisVector> vectors);
  
  // Multi-dimensional (e.g., Correlation matrix, Multi-field time series)
  const factory AnalysisOutput.matrix(List<TimeSeriesMatrix> matrices);
}
```

### Matrix-Vector-Scalar Types
**Location:** `models/matrix_vector_scalar/`

Mathematical type system for structured data analysis.

- **TimeSeriesMatrix** - 2D data with guaranteed structure (1 timestamp + N value columns)
- **ValueVector** - 1D numeric arrays with mathematical operations
- **TimestampVector** - Temporal data with time-specific analysis
- **StatScalar** - Single statistical results with formatting
- **CategoryVector** - Categorical data with encoding

See `models/matrix_vector_scalar/README.md` for complete documentation.

## JavaScript Execution

### Template System
**Location:** `assets/scripts/mvs_shell.js.j2`

Jinja2 template that wraps user logic with data injection, library shims, and error handling. See inline documentation in the template file for detailed explanation.

**Template Variables:**
- `{{ values }}` - List of numeric field values from database
- `{{ timestamps }}` - List of ISO8601 timestamp strings
- `{{ logic_fragment }}` - User's JavaScript code
- `{{ output_mode }}` - Output type: 'scalar' | 'vector' | 'matrix'

**Rendered Output:**
The template produces a complete JavaScript program that:
1. Defines library shims (simple-statistics)
2. Injects data into `data` object
3. Wraps user logic in `runLogic()` function
4. Executes and boxes result as JSON

**Used By:** `WasmAnalysisService._executeInIsolate()`

### Available Libraries

**simple-statistics** - Statistical functions
```javascript
ss.mean(data.values)
ss.median(data.values)
ss.standardDeviation(data.values)
ss.linearRegression(points)
// ... and more
```

### User Script Examples

**Scalar Output:**
```javascript
return ss.mean(data.values);
```

**Vector Output:**
```javascript
return {
  label: 'Weekly Averages',
  values: weeklyAverages
};
```

**Matrix Output:**
```javascript
return {
  label: 'Multi-Field Analysis',
  values: processedData
};
```

## State Management

### MvsPipelineBuilderCubit
**Location:** `cubits/mvs_pipeline_builder_cubit.dart`

Manages pipeline builder UI state and live preview.

**Key Features:**
- Real-time script validation
- Live preview streaming
- Pipeline save/load
- Field selection

**State:**
```dart
@freezed
class MvsPipelineBuilderState {
  UiFlowStatus status;
  String scriptJs;
  String fieldId;
  AnalysisOutputMode outputMode;
  AnalysisOutput? liveResult;
  Object? error;
}
```

### AnalyticsCubit
**Location:** `cubits/analytics_cubit.dart`

Manages dashboard analytics display and KPI streaming.

**Key Features:**
- Stream multiple pipeline results
- Aggregate scalar KPIs
- Handle pipeline errors gracefully

## Usage Examples

### Execute a Pipeline
```dart
final orchestrator = getIt<AnalysisOrchestrator>();

// By ID
final result = await orchestrator.executeById('pipeline-123');

// By model
final pipeline = AnalysisPipelineModel(
  id: 'temp',
  name: 'Test',
  fieldId: 'template-1:mood',
  outputMode: AnalysisOutputMode.scalar,
  shell: AnalysisShell.mvsWasm,
  scriptJs: 'return ss.mean(data.values);',
  updatedAt: DateTime.now(),
);
final result = await orchestrator.execute(pipeline);
```

### Stream Scalar Results
```dart
final orchestrator = getIt<AnalysisOrchestrator>();

orchestrator.streamScalarResults('pipeline-123').listen((scalars) {
  // scalars = {'Mean': 75.2, 'Max': 100.0}
  print('Current KPIs: $scalars');
});
```

### Live Preview in Builder
```dart
final orchestrator = getIt<AnalysisOrchestrator>();

orchestrator.streamLivePreview(
  scriptJs: 'return ss.mean(data.values);',
  fieldId: 'template-1:mood',
  outputMode: AnalysisOutputMode.scalar,
  shell: AnalysisShell.mvsWasm,
).listen((output) {
  output.when(
    scalar: (scalars) => print('Preview: ${scalars.first.value}'),
    vector: (vectors) => print('Preview: ${vectors.first.values.length} points'),
    matrix: (matrices) => print('Preview: ${matrices.first.data.length} rows'),
  );
});
```

## Error Handling

All services use the `tryMethod` pattern from `infrastructure/core/try_operation.dart`:

```dart
Future<AnalysisOutput> execute(AnalysisPipelineModel pipeline) {
  return tryMethod(
    () => _wasmService.execute(pipeline),
    AnalysisException.new,
    'execute',
  );
}
```

**Exception Hierarchy:**
- `AnalysisException` - Base exception for all analysis errors
  - Invalid pipeline configuration
  - JavaScript execution errors
  - Data fetching failures
  - Result parsing errors

## Testing

### Unit Tests
**Location:** `test/logic/analytics/`

- `wasm_analysis_service_test.dart` - JavaScript execution
- `analysis_orchestrator_test.dart` - Orchestration logic
- `mvs_pipeline_builder_cubit_test.dart` - State management

### Integration Tests
**Location:** `test/integration/`

- End-to-end pipeline execution
- Database integration
- Streaming behavior

## Future Enhancements

### Planned Features
1. **Real-time data streaming** - Replace periodic polling with reactive queries
2. **Multi-field analysis** - Support analyzing multiple fields simultaneously
3. **Custom library injection** - Allow users to add custom JavaScript libraries
4. **Pipeline versioning** - Track and rollback pipeline changes
5. **Performance metrics** - Execution time tracking and optimization

### Known Limitations
1. **Matrix output** - Complex matrix parsing not fully implemented
2. **Error recovery** - No automatic retry on transient failures
3. **Data window** - Fixed 90-day window (should be configurable)
4. **Library support** - Only simple-statistics currently available

## Migration Guide

### Using AnalysisOrchestrator (Recommended)

The orchestrator provides a clean, unified API for all analysis operations:

**Execute a pipeline:**
```dart
final orchestrator = getIt<AnalysisOrchestrator>();
final result = await orchestrator.executeById('pipeline-123');
```

**Stream results:**
```dart
orchestrator.streamScalarResults('pipeline-123').listen((scalars) {
  print('Current KPIs: $scalars');
});
```

### Direct Service Usage (Advanced)

For advanced use cases, you can use services directly:

**AnalysisEngine:**
```dart
final engine = getIt<AnalysisEngine>();
final result = await engine.execute(pipeline);
```

**StreamingAnalyticsService:**
```dart
final service = getIt<StreamingAnalyticsService>();
service.streamScalarResults(pipelineId).listen(...);
```

**WasmAnalysisService:**
```dart
final wasmService = getIt<IWasmAnalysisService>();
final result = await wasmService.execute(pipeline);
```

## Related Documentation

- [Matrix-Vector-Scalar System](models/matrix_vector_scalar/README.md)
- [Cubit UI Flow Pattern](../../.kiro/steering/cubit_ui_flow_pattern.md)
- [Data Flow Consistency](../../.kiro/steering/data_flow_consistency.md)
- [Service Repository Pattern](../../.kiro/steering/service_repository_pattern.md)
