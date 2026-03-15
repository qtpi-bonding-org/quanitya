import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../data/dao/log_entry_query_dao.dart';
import '../../../data/interfaces/log_entry_interface.dart';
import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../logic/templates/enums/field_enum.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'results_list_state.dart';

export 'results_list_state.dart';

@injectable
class ResultsListCubit extends QuanityaCubit<ResultsListState> {
  final ILogEntryRepository _logEntryRepo;
  final TemplateWithAestheticsRepository _templateRepo;

  StreamSubscription<List<TemplateSummary>>? _summariesSubscription;
  StreamSubscription<List<TemplateWithAesthetics>>? _templatesSubscription;

  List<TemplateSummary>? _latestSummaries;
  List<TemplateWithAesthetics>? _latestTemplates;

  ResultsListCubit(this._logEntryRepo, this._templateRepo)
      : super(const ResultsListState());

  void load() {
    emit(state.copyWith(status: UiFlowStatus.loading));

    _summariesSubscription?.cancel();
    _summariesSubscription = _logEntryRepo.watchTemplateSummaries().listen(
      (summaries) {
        _latestSummaries = summaries;
        _processAndEmit();
      },
      onError: (e) => emit(state.copyWith(
        status: UiFlowStatus.failure,
        error: e,
      )),
    );

    _templatesSubscription?.cancel();
    _templatesSubscription = _templateRepo.watch(isArchived: false).listen(
      (templates) {
        _latestTemplates = templates;
        _processAndEmit();
      },
      onError: (e) => emit(state.copyWith(
        status: UiFlowStatus.failure,
        error: e,
      )),
    );
  }

  void _processAndEmit() {
    final summaries = _latestSummaries;
    final templates = _latestTemplates;
    if (summaries == null || templates == null) return;

    final templateMap = {
      for (final t in templates) t.template.id: t,
    };

    final graphableTypes = {
      FieldEnum.integer,
      FieldEnum.float,
      FieldEnum.dimension,
      FieldEnum.boolean,
      FieldEnum.enumerated,
      FieldEnum.location,
    };

    final items = summaries
        .where(
            (s) => s.entryCount > 0 && templateMap.containsKey(s.templateId))
        .map((s) {
          final t = templateMap[s.templateId]!;
          return ResultsTemplateItem(
            templateId: s.templateId,
            templateName: t.template.name,
            entryCount: s.entryCount,
            lastLoggedAt: s.lastLoggedAt,
            hasGraphableFields: t.template.fields
                .any((f) => graphableTypes.contains(f.type)),
          );
        })
        .toList()
      ..sort((a, b) {
        if (a.lastLoggedAt == null && b.lastLoggedAt == null) return 0;
        if (a.lastLoggedAt == null) return 1;
        if (b.lastLoggedAt == null) return -1;
        return b.lastLoggedAt!.compareTo(a.lastLoggedAt!);
      });

    emit(state.copyWith(
      status: UiFlowStatus.success,
      templates: items,
    ));
  }

  @override
  Future<void> close() {
    _summariesSubscription?.cancel();
    _templatesSubscription?.cancel();
    return super.close();
  }
}
