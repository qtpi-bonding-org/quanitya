import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/try_operation.dart';
import 'exceptions/notification_exception.dart';
import 'notification_action_handler.dart';

/// Notification category IDs.
abstract final class NotificationCategories {
  /// Category for schedule reminder notifications with Quick Log + Open Entry actions.
  static const reminder = 'reminder';
}

/// General-purpose notification service for local push notifications.
///
/// Provides a simple API for:
/// - Showing immediate notifications
/// - Scheduling future notifications (with optional action categories)
/// - Canceling notifications
/// - Listing pending notifications
@lazySingleton
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final INotificationActionHandler _actionHandler;

  /// Android notification channel configuration.
  static const _androidChannel = AndroidNotificationDetails(
    'quanitya_reminders',
    'Reminders',
    channelDescription: 'Scheduled reminders for your trackers',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Android notification details with action buttons for reminders.
  static const _androidReminderChannel = AndroidNotificationDetails(
    'quanitya_reminders',
    'Reminders',
    channelDescription: 'Scheduled reminders for your trackers',
    importance: Importance.high,
    priority: Priority.high,
    actions: [
      AndroidNotificationAction(
        NotificationActionIds.quickLog,
        'Quick Log',
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        NotificationActionIds.openEntry,
        'Log Entry',
        showsUserInterface: true,
      ),
    ],
  );

  /// iOS/macOS notification configuration.
  static const _darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  /// iOS/macOS notification configuration for reminders (with category).
  static const _darwinReminderDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    categoryIdentifier: NotificationCategories.reminder,
  );

  /// Default notification details for all platforms (no actions).
  static const _notificationDetails = NotificationDetails(
    android: _androidChannel,
    iOS: _darwinDetails,
    macOS: _darwinDetails,
  );

  /// Notification details with action buttons for reminders.
  static const _reminderNotificationDetails = NotificationDetails(
    android: _androidReminderChannel,
    iOS: _darwinReminderDetails,
    macOS: _darwinReminderDetails,
  );

  NotificationService(this._actionHandler)
      : _plugin = FlutterLocalNotificationsPlugin();

  /// Initialize the notification plugin.
  ///
  /// Must be called before any other methods.
  /// Returns true if initialization succeeded.
  Future<bool> initialize() {
    return tryMethod(
      () async {
        debugPrint('NotificationService: Initializing...');

        // Initialize timezone data
        tz_data.initializeTimeZones();

        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        // iOS categories with action buttons
        // Both actions use foreground option so the callback fires reliably.
        // Quick Log opens the app briefly but completes instantly.
        final darwinSettings = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              NotificationCategories.reminder,
              actions: [
                DarwinNotificationAction.plain(
                  NotificationActionIds.quickLog,
                  'Quick Log',
                  options: {DarwinNotificationActionOption.foreground},
                ),
                DarwinNotificationAction.plain(
                  NotificationActionIds.openEntry,
                  'Log Entry',
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        );
        debugPrint('NotificationService: Registered reminder category with '
            '${NotificationActionIds.quickLog} and ${NotificationActionIds.openEntry} actions');

        final initSettings = InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        );

        final result = await _plugin.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationResponse,
        );

        debugPrint('NotificationService: Initialized = $result');
        return result ?? false;
      },
      NotificationException.new,
      'initialize',
    );
  }

  /// Request notification permissions from the user.
  ///
  /// On Android 13+, this shows a system permission dialog.
  /// On iOS/macOS, this requests alert, badge, and sound permissions.
  /// Returns true if permissions were granted.
  Future<bool> requestPermissions() {
    return tryMethod(
      () async {
        debugPrint('NotificationService: Requesting permissions...');

        // Android 13+ permission request
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission();
          debugPrint('NotificationService: Android permission = $granted');
          if (granted != true) return false;
        }

        // iOS permission request
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('NotificationService: iOS permission = $granted');
          return granted ?? false;
        }

        // macOS permission request
        final macPlugin = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
        if (macPlugin != null) {
          final granted = await macPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('NotificationService: macOS permission = $granted');
          return granted ?? false;
        }

        return true;
      },
      NotificationException.new,
      'requestPermissions',
    );
  }

  /// Show an immediate notification.
  ///
  /// [id] - Unique identifier for this notification (used for cancellation)
  /// [title] - Notification title
  /// [body] - Notification body text
  /// [payload] - Optional data to pass when notification is tapped
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    return tryMethod(
      () async {
        debugPrint('NotificationService: Showing notification $id');
        await _plugin.show(
            id, title, body, _notificationDetails, payload: payload);
      },
      NotificationException.new,
      'showNow',
    );
  }

  /// Schedule a notification for a future time.
  ///
  /// [id] - Unique identifier for this notification
  /// [title] - Notification title
  /// [body] - Notification body text
  /// [scheduledAt] - When to show the notification
  /// [payload] - Optional data to pass when notification is tapped
  /// [category] - Optional category for action buttons (e.g., [NotificationCategories.reminder])
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
    String? category,
  }) {
    return tryMethod(
      () async {
        // Don't schedule notifications in the past
        if (scheduledAt.isBefore(DateTime.now())) {
          debugPrint('NotificationService: Skipping past notification $id');
          return;
        }

        final tzScheduledAt = tz.TZDateTime.from(scheduledAt, tz.local);

        // Use reminder details if category matches, otherwise default
        final details = category == NotificationCategories.reminder
            ? _reminderNotificationDetails
            : _notificationDetails;

        debugPrint(
            'NotificationService: Scheduling notification $id for $scheduledAt'
            '${category != null ? ' (category: $category)' : ''}');

        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledAt,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      },
      NotificationException.new,
      'schedule',
    );
  }

  /// Cancel a specific notification by ID.
  Future<void> cancel(int id) {
    return tryMethod(
      () async {
        debugPrint('NotificationService: Canceling notification $id');
        await _plugin.cancel(id);
      },
      NotificationException.new,
      'cancel',
    );
  }

  /// Cancel all pending notifications.
  Future<void> cancelAll() {
    return tryMethod(
      () async {
        debugPrint('NotificationService: Canceling all notifications');
        await _plugin.cancelAll();
      },
      NotificationException.new,
      'cancelAll',
    );
  }

  /// Get list of pending (scheduled) notifications.
  Future<List<PendingNotificationRequest>> getPending() {
    return tryMethod(
      () async {
        return await _plugin.pendingNotificationRequests();
      },
      NotificationException.new,
      'getPending',
    );
  }

  /// Callback when a notification is tapped or an action button is pressed.
  void _onNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;
    final input = response.input;

    debugPrint('NotificationService: Response received - '
        'id=${response.id}, '
        'actionId=${actionId ?? "(none)"}, '
        'payload=${payload ?? "(none)"}, '
        'notificationResponseType=${response.notificationResponseType}');

    if (actionId != null && actionId.isNotEmpty) {
      // Action button pressed
      debugPrint('NotificationService: Dispatching action "$actionId" to handler');
      _actionHandler.handle(
        actionId: actionId,
        payload: payload,
        inputText: input,
      );
    } else {
      // Plain notification tap — treat as "open entry"
      debugPrint('NotificationService: Plain tap, dispatching as open_entry');
      _actionHandler.handle(
        actionId: NotificationActionIds.openEntry,
        payload: payload,
      );
    }
  }
}
