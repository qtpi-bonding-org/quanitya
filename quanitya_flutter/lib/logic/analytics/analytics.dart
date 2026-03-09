/// Single Variable Analytics System
///
/// Pipeline-based analytics using JavaScript snippets executed in WASM.
/// AI generates JS code via LLM, executed in QuickJS sandbox.
///
/// ## Core Components
///
/// ### Models
/// - `AnalysisPipelineModel`: Pipeline with JS snippet and output mode
/// - MVS types: `StatScalar`, `ValueVector`, `TimeSeriesMatrix`, etc.
///
/// ### Services
/// - `AnalysisEngine`: Orchestrates pipeline execution
/// - `WasmAnalysisService`: Executes JS in QuickJS WASM sandbox
/// - `StreamingAnalyticsService`: Real-time streaming results
/// - `AiAnalysisOrchestrator`: LLM-powered JS snippet generation
/// - `FieldContextService`: Field metadata for AI context
///
/// ### Cubits
/// - `AnalysisBuilderCubit`: Pipeline builder state management
library;

export 'models/analysis_pipeline.dart';
export 'models/matrix_vector_scalar/matrix_vector_scalar.dart';
export 'enums/time_resolution.dart';
export 'enums/calculation.dart';
export 'services/analysis_engine.dart';
export 'exceptions/analysis_exceptions.dart';
