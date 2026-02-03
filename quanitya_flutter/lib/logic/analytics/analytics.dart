/// Single Variable Analytics System
/// 
/// This module implements a flexible pipeline-based analytics system for processing
/// single variable data from log entries. It provides generic mathematical building
/// blocks that can be combined to create custom analysis workflows.
library;
/// 
/// ## Core Components
/// 
/// ### Models
/// - `AnalysisPipelineModel`: Defines analysis workflows with steps and time resolution
/// - `AnalysisStep`: Individual calculation steps in a pipeline
/// - `AnalysisResult`: Union type for pipeline execution results
/// 
/// ### Enums
/// - `TimeResolution`: second, minute, hour, day, week
/// - `Calculation`: Complete set of mathematical building blocks:
///   - Data extraction: extractValues
///   - Basic statistics: mean, median, mode, standardDeviation, variance, min, max, sum, range
///   - Percentiles: percentile (with parameter support)
///   - Time series: rollingAverage, analyzeFrequency
///   - Growth/Change: percentChange, difference
///   - Math operations: abs
/// - `DataType`: timeSeries, collection, scalar
/// 
/// ### Services
/// - `AnalysisEngine`: Executes pipelines with type-safe step processing
/// - `PipelineFactory`: Creates generic pipeline building blocks (not domain-specific templates)
/// - `CalculationService`: Pure calculation functions (already existed)
/// 
/// ### Data Layer
/// - `AnalysisPipelineDualDao`: E2EE dual DAO for pipeline storage
/// - `AnalysisPipelineRepository`: Repository with tryMethod error handling
/// - `IAnalysisPipelineRepository`: Repository interface
/// 
/// ### UI Layer
/// - `AnalyticsCubit`: State management with cubit UI flow pattern
/// - `AnalyticsState`: State with IUiFlowState implementation
/// - `AnalyticsMessageMapper`: Maps operations to localized messages
/// 
/// ## Database Schema
/// 
/// ### Local Tables (Plaintext)
/// - `analysis_pipelines`: Pipeline configurations for performance
/// 
/// ### Encrypted Tables (E2EE)
/// - `encrypted_analysis_pipelines`: Encrypted pipeline data for sync
/// 
/// ## Generic Building Block Usage
/// 
/// ```dart
/// // Create a simple mean calculation pipeline
/// final pipeline = PipelineFactory().createExtractAndCalculatePipeline(
///   name: 'Average Value',
///   fieldId: 'my_field_id',
///   timeResolution: TimeResolution.day,
///   calculation: Calculation.mean,
/// );
/// 
/// // Create a custom multi-step pipeline
/// var pipeline = PipelineFactory().createEmptyPipeline(
///   name: 'Custom Analysis',
///   fieldId: 'my_field_id', 
///   timeResolution: TimeResolution.hour,
/// );
/// 
/// pipeline = PipelineFactory().addStep(pipeline, AnalysisStep(
///   function: Calculation.extractValues,
///   inputType: DataType.timeSeries,
///   outputType: DataType.collection,
/// ));
/// 
/// pipeline = PipelineFactory().addStep(pipeline, AnalysisStep(
///   function: Calculation.standardDeviation,
///   inputType: DataType.collection,
///   outputType: DataType.scalar,
/// ));
/// 
/// // Execute the pipeline
/// await analyticsCubit.savePipeline(pipeline);
/// await analyticsCubit.executePipeline(pipeline);
/// ```
/// 
/// ## Mathematical Building Blocks
/// 
/// ### Basic Statistics
/// ```dart
/// // Mean, median, mode, standard deviation, variance
/// AnalysisStep(function: Calculation.mean, ...)
/// AnalysisStep(function: Calculation.standardDeviation, ...)
/// ```
/// 
/// ### Percentiles with Parameters
/// ```dart
/// AnalysisStep(
///   function: Calculation.percentile,
///   params: {"value": 75.0}, // 75th percentile
///   ...
/// )
/// ```
/// 
/// ### Time Series Operations
/// ```dart
/// AnalysisStep(
///   function: Calculation.rollingAverage,
///   params: {"windowDays": 7}, // 7-day rolling average
///   ...
/// )
/// ```
/// 
/// ### Growth Analysis
/// ```dart
/// AnalysisStep(function: Calculation.percentChange, ...)
/// AnalysisStep(function: Calculation.difference, ...)
/// ```
/// 
/// ## Architecture Benefits
/// 
/// - **Generic Building Blocks**: Mathematical operations, not domain-specific templates
/// - **Type Safety**: Compile-time validation of pipeline steps
/// - **E2EE Support**: Automatic encryption for sensitive analytics
/// - **Flexible Resolution**: Second to week-level time grouping
/// - **Extensible**: Easy to add new calculations and data types
/// - **UI Integration**: Automatic loading/error/success feedback
/// - **Performance**: Local plaintext storage for fast queries
/// - **Sync Ready**: PowerSync integration for multi-device sync
/// - **Parameter Support**: Configurable calculations (percentiles, rolling windows)
/// - **Composable**: Build complex analysis from simple mathematical steps

export 'models/analysis_pipeline.dart';
export 'models/matrix_vector_scalar/matrix_vector_scalar.dart';
export 'enums/time_resolution.dart';
export 'enums/calculation.dart';
export 'services/analysis_engine.dart';
export 'services/pipeline_factory.dart';
export 'cubits/analytics_cubit.dart';
export 'cubits/analytics_state.dart';
export 'cubits/analytics_message_mapper.dart';
export 'exceptions/analysis_exceptions.dart';