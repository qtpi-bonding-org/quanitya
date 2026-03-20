import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../data/dao/template_query_dao.dart';
import '../../data/interfaces/log_entry_interface.dart';
import '../../logic/log_entries/models/log_entry.dart';
import '../../logic/log_entries/services/log_entry_service.dart';
import '../../logic/templates/enums/field_enum.dart';
import '../../logic/templates/models/shared/template_field.dart';
import '../../logic/templates/models/shared/tracker_template.dart';

/// Action IDs used in notification action buttons.
abstract final class NotificationActionIds {
  static const quickLog = 'quick_log';
  static const openEntry = 'open_entry';
}

/// Interface for handling notification action button presses.
abstract class INotificationActionHandler {
  /// Handle a notification action.
  ///
  /// [actionId] - The ID of the action button pressed (or null for plain tap)
  /// [payload] - The notification payload (todo entry ID)
  /// [inputText] - Optional text input from the notification (future use)
  Future<void> handle({
    required String actionId,
    required String? payload,
    String? inputText,
  });

  /// Stream of entry IDs that should trigger deep link navigation.
  ///
  /// Emitted when the user taps "Open Entry" or plain-taps a notification.
  /// The app shell should listen to this stream and navigate accordingly.
  Stream<String> get deepLinkRequests;
}

/// Implementation of [INotificationActionHandler].
///
/// Handles:
/// - [NotificationActionIds.quickLog]: Logs the todo with default values
/// - [NotificationActionIds.openEntry]: Emits deep link for navigation
@LazySingleton(as: INotificationActionHandler)
class NotificationActionHandler implements INotificationActionHandler {
  final LogEntryService _logEntryService;
  final ILogEntryRepository _logEntryRepo;
  final TemplateQueryDao _templateQueryDao;

  final _deepLinkController = StreamController<String>.broadcast();

  NotificationActionHandler(
    this._logEntryService,
    this._logEntryRepo,
    this._templateQueryDao,
  );

  @override
  Stream<String> get deepLinkRequests => _deepLinkController.stream;

  @override
  Future<void> handle({
    required String actionId,
    required String? payload,
    String? inputText,
  }) async {
    debugPrint('NotificationActionHandler: action=$actionId, payload=$payload');

    if (payload == null || payload.isEmpty) {
      debugPrint('NotificationActionHandler: No payload, ignoring');
      return;
    }

    switch (actionId) {
      case NotificationActionIds.quickLog:
        await _handleQuickLog(payload);
      case NotificationActionIds.openEntry:
        _handleOpenEntry(payload);
      default:
        debugPrint('NotificationActionHandler: Unknown action $actionId');
    }
  }

  /// Log the todo entry with default values without opening the app.
  Future<void> _handleQuickLog(String todoId) async {
    try {
      // Fetch the todo entry
      final todo = await _logEntryRepo.getEntry(todoId);
      if (todo == null) {
        debugPrint('NotificationActionHandler: Todo $todoId not found');
        return;
      }

      // Already logged — skip
      if (todo.occurredAt != null) {
        debugPrint('NotificationActionHandler: Todo $todoId already logged');
        return;
      }

      // Fetch template to build default values
      final template = await _templateQueryDao.findById(todo.templateId);
      if (template == null) {
        debugPrint('NotificationActionHandler: Template ${todo.templateId} not found');
        return;
      }

      // Build default values and save as logged entry
      final data = _buildDefaultValues(template);
      final loggedEntry = LogEntryModel.logNow(
        templateId: todo.templateId,
        data: data,
      );
      await _logEntryService.saveLogEntry(loggedEntry);

      // Delete the todo (it's been fulfilled)
      await _logEntryRepo.deleteLogEntry(todoId);

      // Note: the OS dismisses the notification when the action button is tapped

      debugPrint('NotificationActionHandler: Quick logged for template ${template.name}');
    } catch (e) {
      debugPrint('NotificationActionHandler: Quick log failed: $e');
    }
  }

  /// Emit a deep link request for navigation.
  void _handleOpenEntry(String todoId) {
    _deepLinkController.add(todoId);
  }

  /// Builds default values map from template fields.
  ///
  /// Mirrors the logic in TemplateListCubit._buildDefaultValues.
  Map<String, dynamic> _buildDefaultValues(TrackerTemplateModel template) {
    final defaults = <String, dynamic>{};
    for (final field in template.fields) {
      if (field.isDeleted) continue;
      defaults[field.id] = field.defaultValue ?? _typeDefault(field);
    }
    return defaults;
  }

  /// Returns type-based default value for a field.
  dynamic _typeDefault(TemplateField field) {
    return switch (field.type) {
      FieldEnum.integer => 0,
      FieldEnum.float => 0.0,
      FieldEnum.boolean => false,
      FieldEnum.text => '',
      FieldEnum.datetime => DateTime.now().toIso8601String(),
      FieldEnum.enumerated =>
        field.options?.isNotEmpty == true ? field.options!.first : null,
      FieldEnum.dimension => 0.0,
      FieldEnum.reference => null,
      FieldEnum.location => null,
      FieldEnum.group => null,
      FieldEnum.multiEnum => <String>[],
    };
  }
}
