import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../../data/dao/log_entry_query_dao.dart';
import '../../../../data/interfaces/log_entry_interface.dart';
import '../../../../logic/log_entries/models/log_entry.dart';
import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import 'entry_detail_state.dart';

export 'entry_detail_state.dart';

/// Cubit for loading, updating, and deleting a single log entry.
@injectable
class EntryDetailCubit extends QuanityaCubit<EntryDetailState> {
  final LogEntryQueryDao _queryDao;
  final ILogEntryRepository _repository;

  EntryDetailCubit(this._queryDao, this._repository) 
      : super(const EntryDetailState());

  /// Load entry by ID with template, aesthetics, and schedule context.
  Future<void> loadEntry(String entryId) async {
    await tryOperation(() async {
      final entry = await _queryDao.findByIdWithContext(entryId);
      if (entry == null) {
        throw StateError('Entry not found: $entryId');
      }
      return state.copyWith(
        entry: entry,
        status: UiFlowStatus.success,
        lastOperation: EntryDetailOperation.load,
      );
    }, emitLoading: true);
  }

  /// Initialize with pre-loaded entry (from navigation).
  void initWithEntry(LogEntryWithContext entry) {
    emit(state.copyWith(entry: entry));
  }

  /// Update the current entry with new data.
  Future<void> updateEntry(LogEntryModel updatedEntry) async {
    await tryOperation(() async {
      await _repository.updateLogEntry(updatedEntry);
      // Reload to get fresh context
      final refreshed = await _queryDao.findByIdWithContext(updatedEntry.id);
      return state.copyWith(
        entry: refreshed,
        status: UiFlowStatus.success,
        lastOperation: EntryDetailOperation.update,
      );
    }, emitLoading: true);
  }

  /// Delete the current entry.
  Future<void> deleteEntry() async {
    final entryId = state.entry?.entry.id;
    if (entryId == null) return;

    await tryOperation(() async {
      await _repository.deleteLogEntry(entryId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: EntryDetailOperation.delete,
      );
    }, emitLoading: true);
  }
}
