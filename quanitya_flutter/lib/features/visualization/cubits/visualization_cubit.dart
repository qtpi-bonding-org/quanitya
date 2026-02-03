import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../data/repositories/data_retrieval_service.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'visualization_state.dart';

export 'visualization_state.dart';

/// Cubit for loading visualization data with statistics.
@injectable
class VisualizationCubit extends QuanityaCubit<VisualizationState> {
  final DataRetrievalService _dataRepo;

  VisualizationCubit(this._dataRepo)
      : super(const VisualizationState());

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

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: VisualizationOperation.load,
        data: data,
        consistencyRate: consistencyRate.clamp(0.0, 1.0),
        overlayFields: {},
      );
    }, emitLoading: true);
  }

  /// Toggle a numeric field for overlay mode.
  /// 
  /// ✅ UI-ONLY STATE: This is a temporary visualization preference that doesn't need
  /// to persist to the database. It's only used for the current visualization session
  /// and is reset when the user navigates away or reloads the visualization.
  void toggleOverlayField(String fieldLabel) {
    final current = Set<String>.from(state.overlayFields);
    if (current.contains(fieldLabel)) {
      current.remove(fieldLabel);
    } else {
      current.add(fieldLabel);
    }
    emit(state.copyWith(overlayFields: current));
  }

  /// Clear all overlay selections.
  /// 
  /// ✅ UI-ONLY STATE: Clears temporary visualization preferences.
  void clearOverlay() {
    emit(state.copyWith(overlayFields: {}));
  }
}
