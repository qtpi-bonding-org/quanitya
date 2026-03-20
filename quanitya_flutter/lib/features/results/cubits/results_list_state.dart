import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'results_list_state.freezed.dart';

/// A template with its entry summary for the Results list.
class ResultsTemplateItem {
  final String templateId;
  final String templateName;
  final int entryCount;
  final DateTime? lastLoggedAt;
  final bool hasGraphableFields;
  final bool hasAnalyzableFields;
  final bool isHidden;
  final String? icon;
  final String? emoji;
  final String? accentColorHex;

  const ResultsTemplateItem({
    required this.templateId,
    required this.templateName,
    required this.entryCount,
    this.lastLoggedAt,
    this.hasGraphableFields = true,
    this.hasAnalyzableFields = false,
    this.isHidden = false,
    this.icon,
    this.emoji,
    this.accentColorHex,
  });
}

@freezed
class ResultsListState
    with _$ResultsListState, UiFlowStateMixin
    implements IUiFlowState {
  const ResultsListState._();

  const factory ResultsListState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    @Default([]) List<ResultsTemplateItem> templates,
  }) = _ResultsListState;
}
