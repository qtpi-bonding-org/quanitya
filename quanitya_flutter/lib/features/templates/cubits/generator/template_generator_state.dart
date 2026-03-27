import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/repositories/template_with_aesthetics_repository.dart';

part 'template_generator_state.freezed.dart';

enum GeneratorOperation { generate, save, discard }

@freezed
abstract class TemplateGeneratorState
    with _$TemplateGeneratorState, UiFlowStateMixin
    implements IUiFlowState {
  const TemplateGeneratorState._();

  const factory TemplateGeneratorState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    GeneratorOperation? lastOperation,
    String? prompt,
    TemplateWithAesthetics? preview,
  }) = _TemplateGeneratorState;
}
