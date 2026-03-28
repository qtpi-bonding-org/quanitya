/// Single Variable Analytics System
///
/// Script-based analytics using JavaScript snippets executed in WASM.
/// AI generates JS code via LLM, executed in QuickJS sandbox.
///
/// ## Core Components
///
/// ### Models
/// - `AnalysisScriptModel`: Script with JS snippet and output mode
/// - MVS types: `StatScalar`, `ValueVector`, `TimeSeriesMatrix`, etc.
///
/// ### Services
/// - `AnalysisEngine`: Orchestrates script execution
/// - `WasmAnalysisService`: Executes JS in QuickJS WASM sandbox
/// - `StreamingAnalyticsService`: Real-time streaming results
/// - `AiAnalysisOrchestrator`: LLM-powered JS snippet generation
/// - `FieldShapeResolver`: Resolves field data shapes for AI prompts
///
/// ### Cubits
/// - `AnalysisBuilderCubit`: Script builder state management
library;

export 'models/analysis_script.dart';
export 'models/matrix_vector_scalar/matrix_vector_scalar.dart';
export 'enums/time_resolution.dart';
export 'enums/calculation.dart';
export 'services/analysis_engine.dart';
export 'exceptions/analysis_exceptions.dart';
