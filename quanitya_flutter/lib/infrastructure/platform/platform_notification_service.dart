import 'package:injectable/injectable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/debug_log.dart';

import '../core/try_operation.dart';
import '../notifications/notification_service.dart';
import '../notifications/exceptions/notification_exception.dart';
import 'platform_capability_service.dart';

const _tag = 'infrastructure/platform/platform_notification_service';

/// Platform-aware notification service that gracefully handles unsupported platforms.
/// 
/// On supported platforms: Uses NotificationService
/// On unsupported platforms: Logs warnings and returns success (no-op)
@injectable
class PlatformNotificationService {
  final PlatformCapabilityService _capabilities;
  final NotificationService? _notificationService;

  PlatformNotificationService(
    this._capabilities,
    NotificationService notificationService,
  ) : _notificationService = _capabilities.supportsLocalNotifications
            ? notificationService
            : null;

  /// Initialize the notification service.
  Future<bool> initialize() {
    return tryMethod(
      () async {
        if (!_capabilities.supportsLocalNotifications) {
          Log.d(_tag, '⚠️ ${_capabilities.platformName}: Local notifications not supported');
          return false;
        }
        
        if (_notificationService == null) {
          throw StateError('NotificationService not initialized');
        }
        return await _notificationService.initialize();
      },
      NotificationException.new,
      'initialize',
    );
  }

  /// Show an immediate notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    return tryMethod(
      () async {
        if (!_capabilities.supportsLocalNotifications) {
          Log.d(_tag, '⚠️ ${_capabilities.platformName}: Skipping notification - $title: $body');
          return;
        }
        
        if (_notificationService == null) {
          throw StateError('NotificationService not initialized');
        }
        await _notificationService.showNow(
          id: id,
          title: title,
          body: body,
          payload: payload,
        );
      },
      NotificationException.new,
      'showNotification',
    );
  }

  /// Schedule a notification for the future.
  ///
  /// [category] - Optional notification category for action buttons.
  /// On platforms that don't support actions, the category is ignored
  /// and the notification is shown without action buttons.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String? category,
  }) {
    return tryMethod(
      () async {
        if (!_capabilities.supportsLocalNotifications) {
          Log.d(_tag, '⚠️ ${_capabilities.platformName}: Skipping scheduled notification - $title at $scheduledDate');
          return;
        }

        if (_notificationService == null) {
          throw StateError('NotificationService not initialized');
        }
        await _notificationService.schedule(
          id: id,
          title: title,
          body: body,
          scheduledAt: scheduledDate,
          payload: payload,
          // Only pass category on platforms that support action buttons
          category: _capabilities.supportsNotificationActions ? category : null,
        );
      },
      NotificationException.new,
      'scheduleNotification',
    );
  }

  /// Cancel a specific notification.
  Future<void> cancelNotification(int id) {
    return tryMethod(
      () async {
        if (!_capabilities.supportsLocalNotifications) {
          return; // No-op on unsupported platforms
        }
        
        if (_notificationService == null) {
          throw StateError('NotificationService not initialized');
        }
        await _notificationService.cancel(id);
      },
      NotificationException.new,
      'cancelNotification',
    );
  }

  /// Cancel all notifications.
  Future<void> cancelAllNotifications() {
    return tryMethod(
      () async {
        if (!_capabilities.supportsLocalNotifications) {
          return; // No-op on unsupported platforms
        }
        
        if (_notificationService == null) {
          throw StateError('NotificationService not initialized');
        }
        await _notificationService.cancelAll();
      },
      NotificationException.new,
      'cancelAllNotifications',
    );
  }

  /// Get list of pending notifications.
  Future<List<PendingNotificationRequest>> getPendingNotifications() {
    return tryMethod(
      () async {
        if (!_capabilities.supportsLocalNotifications) {
          return <PendingNotificationRequest>[]; // Empty list on unsupported platforms
        }
        
        if (_notificationService == null) {
          throw StateError('NotificationService not initialized');
        }
        return await _notificationService.getPending();
      },
      NotificationException.new,
      'getPendingNotifications',
    );
  }
  
  /// Whether notifications are supported on this platform.
  bool get isSupported => _capabilities.supportsLocalNotifications;
  
  /// User-friendly message explaining notification limitations.
  String? get limitationMessage {
    if (!_capabilities.supportsLocalNotifications) {
      return 'Local notifications are not available on ${_capabilities.platformName}. '
             'Reminders will only show when the app is open.';
    }
    return null;
  }
}