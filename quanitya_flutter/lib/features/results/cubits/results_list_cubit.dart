import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../data/interfaces/log_entry_interface.dart';
import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'results_list_state.dart';

export 'results_list_state.dart';

@injectable
class ResultsListCubit extends QuanityaCubit<ResultsListState> {
  final ILogEntryRepository _logEntryRepo;
  final TemplateWithAestheticsRepository _templateRepo;

  ResultsListCubit(this._logEntryRepo, this._templateRepo)
      : super(const ResultsListState());

  Future<void> load() => tryOperation(() async {
        final summaries = await _logEntryRepo.getTemplateSummaries();
        final templates = await _templateRepo.find(isArchived: false);

        final nameMap = {
          for (final t in templates) t.template.id: t.template.name,
        };

        final items = summaries
            .where(
                (s) => s.entryCount > 0 && nameMap.containsKey(s.templateId))
            .map((s) => ResultsTemplateItem(
                  templateId: s.templateId,
                  templateName: nameMap[s.templateId]!,
                  entryCount: s.entryCount,
                  lastLoggedAt: s.lastLoggedAt,
                ))
            .toList()
          ..sort((a, b) {
            if (a.lastLoggedAt == null && b.lastLoggedAt == null) return 0;
            if (a.lastLoggedAt == null) return 1;
            if (b.lastLoggedAt == null) return -1;
            return b.lastLoggedAt!.compareTo(a.lastLoggedAt!);
          });

        return state.copyWith(
          status: UiFlowStatus.success,
          templates: items,
        );
      }, emitLoading: true);
}
