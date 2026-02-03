import 'package:injectable/injectable.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

import '../dao/error_box_dao.dart';

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
  Future<void> saveError(ErrorEntry error) async {
    await _dao.saveError(error);
  }

  @override
  Future<List<ErrorBoxEntry>> getUnsentErrors() async {
    return _dao.getUnsentErrors();
  }

  @override
  Future<int> getUnsentCount() async {
    final errors = await _dao.getUnsentErrors();
    return errors.length;
  }

  @override
  Future<ErrorBoxEntry?> getErrorById(String id) async {
    return _dao.getErrorById(id);
  }

  @override
  Future<void> markAsSent(String id) async {
    await _dao.markAsSent(id);
  }

  @override
  Future<void> deleteError(String id) async {
    await _dao.deleteError(id);
  }

  /// Clear all sent errors (convenience method, not in interface)
  Future<void> clearSentErrors() async {
    await _dao.clearSentErrors();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Convenience operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Send an error and mark it as sent
  Future<void> sendError(String id, Future<void> Function(ErrorEntry) reporter) async {
    final errorBoxEntry = await _dao.getErrorById(id);
    if (errorBoxEntry == null) return;
    
    await reporter(errorBoxEntry.errorData);
    await _dao.markAsSent(id);
  }

  /// Send all unsent errors
  Future<void> sendAllErrors(Future<void> Function(ErrorEntry) reporter) async {
    final errors = await _dao.getUnsentErrors();
    for (final error in errors) {
      await reporter(error.errorData);
      await _dao.markAsSent(error.id);
    }
  }
}
