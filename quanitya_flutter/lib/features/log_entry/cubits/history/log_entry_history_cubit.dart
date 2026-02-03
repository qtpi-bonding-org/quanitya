import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../data/interfaces/log_entry_interface.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import 'log_entry_history_state.dart';

@injectable
class LogEntryHistoryCubit extends QuanityaCubit<LogEntryHistoryState> {
  final ILogEntryRepository _logEntryRepo;
  final TemplateWithAestheticsRepository _templateRepo;
  StreamSubscription? _entriesSubscription;
  StreamSubscription? _templateSubscription;

  LogEntryHistoryCubit(
    this._logEntryRepo,
    this._templateRepo,
  ) : super(const LogEntryHistoryState());

  Future<void> load(String templateId) async {
    await tryOperation(() async {
      // Cancel existing subscriptions
      await _entriesSubscription?.cancel();
      await _templateSubscription?.cancel();

      // Subscribe to template updates
      _templateSubscription = _templateRepo.watchById(templateId).listen(
        (template) {
           emit(state.copyWith(template: template));
        },
        onError: (e) {
           // We don't want to break the UI flow for template aesthetic updates failure, just log or ignore
           // But if it's critical, we could emit error.
           // For now, let's keep it simple.
        }
      );

      // Subscribe to log entries
      _entriesSubscription = _logEntryRepo.watchEntriesForTemplate(templateId).listen(
        (entries) {
          emit(state.copyWith(
            entries: entries,
            status: UiFlowStatus.success, // Ensure we mark as success when data arrives
          ));
        },
        onError: (e) {
           emit(createErrorState(e));
        }
      );
      
      // Perform an initial fetch or just wait for streams. 
      // To satisfy tryOperation contract and show loading initially, we return success status.
      // The streams will emit updates shortly.
      
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: LogEntryHistoryOperation.load,
      );
    }, emitLoading: true);
  }

  @override
  Future<void> close() {
    _entriesSubscription?.cancel();
    _templateSubscription?.cancel();
    return super.close();
  }
}
