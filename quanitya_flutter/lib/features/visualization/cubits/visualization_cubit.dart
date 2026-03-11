import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../data/interfaces/analysis_pipeline_interface.dart';
import '../../../data/repositories/data_retrieval_service.dart';
import '../../../logic/analytics/services/analysis_engine.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'visualization_state.dart';

export 'visualization_state.dart';

/// Cubit for loading visualization data with statistics.
@injectable
class VisualizationCubit extends QuanityaCubit<VisualizationState> {
  final DataRetrievalService _dataRepo;
  final IAnalysisPipelineRepository _pipelineRepo;
  final AnalysisEngine _analysisEngine;

  VisualizationCubit(
    this._dataRepo,
    this._pipelineRepo,
    this._analysisEngine,
  ) : super(const VisualizationState());

  /// Load visualization data for a template.
  Future<void> loadForTemplate(String templateId, {int days = 30}) async {
    await tryOperation(() async {
      final data = await _dataRepo.getAggregatedData(templateId, days: days);

      if (data == null) {
        throw StateError('Template not found: $templateId');
      }

      // Calculate consistency rate
      final totalDays = data.endDate.difference(data.startDate).inDays + 1;
      final loggedDays = data.loggedDates.length;
      final consistencyRate = totalDays > 0 ? loggedDays / totalDays : 0.0;

      // Load and execute analysis pipelines for this template's fields
      // Pipeline fieldIds use "templateId:fieldLabel" format
      // Load pipelines for this template
      // Pipeline fieldIds use "templateId:fieldLabel" format
      final pipelines = await _pipelineRepo.getAllPipelines();
      final relevantPipelines = pipelines.where(
        (p) => p.fieldId.startsWith('$templateId:'),
      ).toList();

      final analysisResults = <String, dynamic>{};
      for (final pipeline in relevantPipelines) {
        try {
          final result = await _analysisEngine.execute(pipeline);
          analysisResults[pipeline.id] = {
            'pipeline': pipeline,
            'result': result,
          };
        } catch (e) {
          // Log error but continue with other pipelines
          print('Failed to execute pipeline ${pipeline.name}: $e');
        }
      }

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: VisualizationOperation.load,
        data: data,
        consistencyRate: consistencyRate.clamp(0.0, 1.0),
        analysisResults: analysisResults,
      );
    }, emitLoading: true);
  }
}
