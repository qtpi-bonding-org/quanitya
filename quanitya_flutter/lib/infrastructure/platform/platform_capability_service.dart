import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'dart:io' show Platform;

/// Service that checks platform capabilities to enable graceful degradation.
/// 
/// Use this to check if platform-specific features are available before
/// attempting to use them, preventing crashes on unsupported platforms.
@lazySingleton
class PlatformCapabilityService {
  
  // ─────────────────────────────────────────────────────────────────────────
  // Authentication Capabilities
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Whether local authentication (biometrics/device auth) is supported.
  /// 
  /// Supported on: Android (SDK 24+), iOS (13.0+), macOS (10.14+), Windows (10+)
  /// Not supported on: Web, Linux
  bool get supportsLocalAuth {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid || Platform.isMacOS || Platform.isWindows;
  }
  
  /// Whether secure storage (keychain/keystore) is supported.
  /// 
  /// Supported on: Android, iOS, macOS, Windows, Linux, Web (WebCrypto)
  /// Web uses WebCrypto API with localStorage - experimental but functional
  bool get supportsSecureStorage {
    return true; // flutter_secure_storage supports all platforms including web
  }
  
  /// Whether iCloud Keychain sync is supported.
  /// 
  /// Supported on: iOS only
  bool get supportsICloudKeychain {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Notification Capabilities
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Whether local notifications are supported.
  /// 
  /// Supported on: Android, iOS, macOS, Windows, Linux
  /// Not supported on: Web
  bool get supportsLocalNotifications {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid || Platform.isMacOS || 
           Platform.isWindows || Platform.isLinux;
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Data Integration Capabilities
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Whether health data integration is supported.
  /// 
  /// Supported on: iOS (HealthKit), Android (Google Fit)
  /// Not supported on: Web, macOS, Windows, Linux
  bool get supportsHealthData {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }
  
  /// Whether QR code scanning is supported.
  /// 
  /// Supported on: iOS, Android, macOS
  /// Limited on: Web (requires camera permissions)
  /// Not supported on: Windows, Linux
  bool get supportsQRScanning {
    if (kIsWeb) return false; // Camera access limited on web
    return Platform.isIOS || Platform.isAndroid || Platform.isMacOS;
  }
  
  /// Whether QR code generation is supported.
  /// 
  /// Supported on: All platforms
  bool get supportsQRGeneration => true;
  
  // ─────────────────────────────────────────────────────────────────────────
  // Storage & Sync Capabilities
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Whether PowerSync offline-first sync is fully supported.
  /// 
  /// Supported on: iOS, Android, macOS, Windows, Linux
  /// Experimental on: Web (may have WASM/worker issues)
  bool get supportsPowerSync {
    // Web support is experimental - may need fallback
    return true; // Let PowerSync handle web gracefully
  }
  
  /// Whether file system access is supported.
  /// 
  /// Supported on: iOS, Android, macOS, Windows, Linux
  /// Limited on: Web (uses IndexedDB/OPFS instead)
  bool get supportsFileSystem {
    return !kIsWeb;
  }
  
  /// Whether native file sharing is supported.
  /// 
  /// Supported on: iOS, Android, macOS, Windows, Linux
  /// Limited on: Web (uses download instead of share sheet)
  bool get supportsNativeSharing {
    return !kIsWeb;
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Platform Information
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Current platform name for logging/debugging.
  String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
  
  /// Whether this is a mobile platform.
  bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }
  
  /// Whether this is a desktop platform.
  bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }
  
  /// Whether this is a web platform.
  bool get isWeb => kIsWeb;
}