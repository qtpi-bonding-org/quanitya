import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'data_export_state.freezed.dart';

/// Operations for data export/import
enum DataExportOperation {
  export,
  pickFile,
  importData,
}

@freezed
class DataExportState with _$DataExportState, UiFlowStateMixin implements IUiFlowState {
  const DataExportState._();

  const factory DataExportState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    DataExportOperation? lastOperation,
    @Default([]) List<String> pickedTableNames,
  }) = _DataExportState;
}
