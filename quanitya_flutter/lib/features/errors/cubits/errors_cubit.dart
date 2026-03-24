import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../data/repositories/error_box_repository.dart';
import '../../../features/app_syncing_mode/repositories/app_syncing_repository.dart';
import '../../../infrastructure/error_reporting/error_reporter_service.dart';
import 'errors_state.dart';

@lazySingleton
class ErrorsCubit extends QuanityaCubit<ErrorsState> {
  final ErrorBoxRepository _repo;
  final ErrorReporterService _reporter;
  final AppSyncingRepository _settingsRepo;

  StreamSubscription<List<ErrorBoxEntry>>? _errorsSub;

  ErrorsCubit(this._repo, this._reporter, this._settingsRepo)
      : super(const ErrorsState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await load();
      debugPrint('ErrorsCubit: Initialization complete');
    } catch (e) {
      debugPrint('ErrorsCubit: Initialization failed (non-critical): $e');
    }
  }

  /// Start watching unsent errors and load auto-send preference.
  Future<void> load() async {
    final autoSend = await _settingsRepo.getErrorAutoSend();
    emit(state.copyWith(autoSendEnabled: autoSend));

    _errorsSub = _repo.watchUnsentErrors().listen((errors) {
      emit(state.copyWith(unsentErrors: errors));
    });
  }

  /// Toggle auto-send preference.
  Future<void> toggleAutoSend(bool enabled) async {
    await tryOperation(() async {
      await _settingsRepo.updateErrorAutoSend(enabled);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ErrorsOperation.toggleAutoSend,
        autoSendEnabled: enabled,
      );
    });
  }

  /// Send a single error report to the server.
  ///
  /// Does NOT mark as sent — the UI should prompt the user to clear.
  Future<void> sendOne(String errorId) async {
    await tryOperation(() async {
      final entry = await _repo.getErrorById(errorId);
      if (entry == null) throw Exception('Error not found');

      final success = await _reporter.sendErrorReport(entry.errorData);
      if (!success) throw Exception('Failed to send error report');

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ErrorsOperation.sendOne,
        lastSentIds: [errorId],
      );
    }, emitLoading: true);
  }

  /// Send all unsent errors to the server in a single batch.
  ///
  /// Does NOT delete — the UI should prompt the user to clear.
  Future<void> sendAll() async {
    await tryOperation(() async {
      final errors = state.unsentErrors;
      final entries = <ErrorEntry>[];
      final ids = <String>[];

      for (final error in errors) {
        final entry = await _repo.getErrorById(error.id);
        if (entry != null) {
          entries.add(entry.errorData);
          ids.add(error.id);
        }
      }

      if (entries.isEmpty) throw Exception('No error reports to send');

      final sentCount = await _reporter.sendErrorReports(entries);
      if (sentCount == 0) throw Exception('Failed to send error reports');

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ErrorsOperation.sendAll,
        lastSentIds: ids,
        lastSentCount: sentCount,
      );
    }, emitLoading: true);
  }

  /// Mark a single error as sent and remove from unsent list.
  Future<void> markAsSent(String errorId) async {
    await tryOperation(() async {
      await _repo.markAsSent(errorId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ErrorsOperation.markAsSent,
      );
    });
  }

  /// Mark multiple errors as sent.
  Future<void> markAllAsSent(List<String> errorIds) async {
    await tryOperation(() async {
      for (final id in errorIds) {
        await _repo.markAsSent(id);
      }
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ErrorsOperation.markAllAsSent,
      );
    });
  }

  /// Delete a single error from storage.
  Future<void> deleteError(String errorId) async {
    await tryOperation(() async {
      await _repo.deleteError(errorId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ErrorsOperation.delete,
      );
    });
  }

  /// Delete multiple errors from storage.
  Future<void> deleteErrors(List<String> errorIds) async {
    await tryOperation(() async {
      for (final id in errorIds) {
        await _repo.deleteError(id);
      }
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ErrorsOperation.deleteAll,
      );
    });
  }

  @override
  Future<void> close() {
    _errorsSub?.cancel();
    return super.close();
  }
}
