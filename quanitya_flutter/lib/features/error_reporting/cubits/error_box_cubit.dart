import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../data/repositories/error_box_repository.dart';
import '../../../infrastructure/error_reporting/error_reporter_service.dart';
import 'error_box_state.dart';

@injectable
class ErrorBoxCubit extends QuanityaCubit<ErrorBoxState> {
  final ErrorBoxRepository _repo;
  final ErrorReporterService _reporter;

  StreamSubscription<List<ErrorBoxEntry>>? _errorsSub;

  ErrorBoxCubit(this._repo, this._reporter) : super(const ErrorBoxState());

  /// Start watching unsent errors.
  void load() {
    _errorsSub = _repo.watchUnsentErrors().listen((errors) {
      emit(state.copyWith(unsentErrors: errors));
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
        lastOperation: ErrorBoxOperation.sendOne,
        lastSentIds: [errorId],
      );
    }, emitLoading: true);
  }

  /// Send all unsent errors to the server.
  ///
  /// Does NOT mark as sent — the UI should prompt the user to clear.
  Future<void> sendAll() async {
    await tryOperation(() async {
      final sentIds = <String>[];

      for (final error in state.unsentErrors) {
        final entry = await _repo.getErrorById(error.id);
        if (entry == null) continue;

        final success = await _reporter.sendErrorReport(entry.errorData);
        if (success) {
          sentIds.add(error.id);
        } else {
          break;
        }
      }

      if (sentIds.isEmpty) throw Exception('Failed to send error reports');

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ErrorBoxOperation.sendAll,
        lastSentIds: sentIds,
      );
    }, emitLoading: true);
  }

  /// Mark a single error as sent and remove from unsent list.
  Future<void> markAsSent(String errorId) async {
    await tryOperation(() async {
      await _repo.markAsSent(errorId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ErrorBoxOperation.markAsSent,
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
        lastOperation: ErrorBoxOperation.markAllAsSent,
      );
    });
  }

  /// Delete a single error from storage.
  Future<void> deleteError(String errorId) async {
    await tryOperation(() async {
      await _repo.deleteError(errorId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ErrorBoxOperation.delete,
      );
    });
  }

  @override
  Future<void> close() {
    _errorsSub?.cancel();
    return super.close();
  }
}
