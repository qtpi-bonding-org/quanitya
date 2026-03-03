import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../infrastructure/llm/models/llm_types.dart';
import '../../../../logic/templates/services/ai/ai_template_orchestrator.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import 'template_generator_state.dart';

@injectable
class TemplateGeneratorCubit extends QuanityaCubit<TemplateGeneratorState> {
  final AiTemplateOrchestrator _aiService;
  final TemplateWithAestheticsRepository _repository;

  TemplateGeneratorCubit(this._aiService, this._repository)
    : super(const TemplateGeneratorState());

  Future<void> generate(String prompt, LlmConfig config) async {
    await tryOperation(() async {
      emit(state.copyWith(prompt: prompt));

      final parsed = await _aiService.generateTemplate(
        prompt,
        config: config,
        templateName: prompt.split(' ').take(3).join(' '),
      );

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: GeneratorOperation.generate,
        preview: TemplateWithAesthetics.fromParsed(parsed),
      );
    }, emitLoading: true);
  }

  Future<void> save() async {
    await tryOperation(() async {
      if (state.preview == null) {
        throw StateError('No template to save');
      }

      await _repository.save(state.preview!);
      analytics?.trackTemplateCreated();

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: GeneratorOperation.save,
        preview: null,
        prompt: null,
      );
    }, emitLoading: true);
  }

  void discard() {
    emit(
      state.copyWith(
        preview: null,
        prompt: null,
        lastOperation: GeneratorOperation.discard,
      ),
    );
  }
}
