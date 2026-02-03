/// Platform abstraction module for graceful cross-platform handling.
/// 
/// This module provides platform-aware services that gracefully degrade
/// functionality on platforms that don't support certain features.
/// 
/// Key services:
/// - PlatformCapabilityService: Check what's supported on current platform
/// - PlatformSecureStorage: Secure storage using flutter_secure_storage on all platforms
/// - PlatformLocalAuth: Local auth with unsupported platform handling
/// - PlatformNotificationService: Notifications with graceful degradation
/// 
/// Usage:
/// ```dart
/// final capabilities = getIt<PlatformCapabilityService>();
/// if (capabilities.supportsLocalAuth) {
///   final auth = getIt<PlatformLocalAuth>();
///   final result = await auth.authenticate(reason: 'Unlock app');
/// }
/// ```
library platform_module;

export 'platform_capability_service.dart';
export 'platform_secure_storage.dart';
export 'platform_local_auth.dart';
export 'platform_notification_service.dart';