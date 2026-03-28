import 'package:injectable/injectable.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

import '../../infrastructure/core/try_operation.dart';
import '../dao/error_box_dao.dart';

/// Exception type for error box operations.
class ErrorBoxException implements Exception {
  final String message;
  final Object? cause;

  const ErrorBoxException(this.message, [this.cause]);

  @override
  String toString() => 'ErrorBoxException: $message';
}

/// Repository for error box operations.
///
/// Provides streaming access to privacy-preserving error reports
/// with automatic deduplication and user-controlled sending.
@lazySingleton
class ErrorBoxRepository implements ErrorBoxStorage {
  final ErrorBoxDao _dao;

  ErrorBoxRepository(this._dao);

  // ─────────────────────────────────────────────────────────────────────────
  // Stream-based queries (reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch all unsent errors (for Error Box UI)
  Stream<List<ErrorBoxEntry>> watchUnsentErrors() {
    return _dao.watchUnsentErrors();
  }

  /// Watch count of unsent errors (for badge display)
  Stream<int> watchUnsentCount() {
    return _dao.watchUnsentCount();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ErrorBoxStorage implementation (for flutter_error_privserver)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveError(ErrorEntry error) => tryMethod(
    () => _dao.saveError(error),
    ErrorBoxException.new,
    'saveError',
  );

  @override
  Future<List<ErrorBoxEntry>> getUnsentErrors() => tryMethod(
    () => _dao.getUnsentErrors(),
    ErrorBoxException.new,
    'getUnsentErrors',
  );

  @override
  Future<int> getUnsentCount() => tryMethod(
    () async {
      final errors = await _dao.getUnsentErrors();
      return errors.length;
    },
    ErrorBoxException.new,
    'getUnsentCount',
  );

  @override
  Future<ErrorBoxEntry?> getErrorById(String id) => tryMethod(
    () => _dao.getErrorById(id),
    ErrorBoxException.new,
    'getErrorById',
  );

  @override
  Future<void> markAsSent(String id) => tryMethod(
    () => _dao.markAsSent(id),
    ErrorBoxException.new,
    'markAsSent',
  );

  @override
  Future<void> deleteError(String id) => tryMethod(
    () => _dao.deleteError(id),
    ErrorBoxException.new,
    'deleteError',
  );

  /// Clear all sent errors (convenience method, not in interface)
  Future<void> clearSentErrors() => tryMethod(
    () => _dao.clearSentErrors(),
    ErrorBoxException.new,
    'clearSentErrors',
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Convenience operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Send an error and mark it as sent
  Future<void> sendError(String id, Future<void> Function(ErrorEntry) reporter) => tryMethod(
    () async {
      final errorBoxEntry = await _dao.getErrorById(id);
      if (errorBoxEntry == null) return;
      await reporter(errorBoxEntry.errorData);
      await _dao.markAsSent(id);
    },
    ErrorBoxException.new,
    'sendError',
  );

  /// Send all unsent errors
  Future<void> sendAllErrors(Future<void> Function(ErrorEntry) reporter) => tryMethod(
    () async {
      final errors = await _dao.getUnsentErrors();
      for (final error in errors) {
        await reporter(error.errorData);
        await _dao.markAsSent(error.id);
      }
    },
    ErrorBoxException.new,
    'sendAllErrors',
  );
}
