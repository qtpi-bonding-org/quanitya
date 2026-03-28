import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_marketing_names/device_marketing_names.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../config/debug_log.dart';

const _tag = 'infrastructure/device/device_info_service';

/// Service for retrieving device information.
///
/// Provides anonymous device identifiers for device registration
/// and management features. NO PII (personally identifiable information)
/// is collected - only device model/type information.
@lazySingleton
class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final DeviceMarketingNames _marketingNames = DeviceMarketingNames();

  String? _cachedDeviceName;

  /// Get an anonymous device identifier.
  ///
  /// Returns platform-specific device model:
  /// - iOS: "iPhone 15 Pro", "iPad Pro"
  /// - Android: "Samsung Galaxy S24", "Pixel 8"
  /// - macOS: "MacBook Pro", "iMac"
  /// - Windows: "Windows PC"
  /// - Linux: "Linux Device"
  /// - Web: "Chrome", "Safari"
  ///
  /// NO user names, OS versions, or PII are included.
  Future<String> getDeviceName() async {
    if (_cachedDeviceName != null) {
      return _cachedDeviceName!;
    }

    try {
      _cachedDeviceName = await _getDeviceNameInternal();
    } catch (e) {
      Log.d(_tag, 'DeviceInfoService: Failed to get device name: $e');
      _cachedDeviceName = _getFallbackName();
    }

    if (_cachedDeviceName == null) {
      throw StateError('Failed to determine device name');
    }
    return _cachedDeviceName!;
  }

  Future<String> _getDeviceNameInternal() async {
    if (kIsWeb) {
      return _getWebDeviceName();
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      // Uses device_marketing_names to convert "iPhone16,2" -> "iPhone 15 Pro Max"
      final name = _marketingNames.getSingleNameFromModel(
        DeviceType.ios,
        info.utsname.machine,
      );
      return name.isNotEmpty ? name : 'iPhone';
    }

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      // Uses device_marketing_names for Android model lookup
      final name = _marketingNames.getSingleNameFromModel(
        DeviceType.android,
        info.model,
      );
      return name.isNotEmpty ? name : '${_capitalize(info.brand)} ${info.model}';
    }

    if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      return _formatMacModel(info.model);
    }

    if (Platform.isWindows) {
      return 'Windows PC';
    }

    if (Platform.isLinux) {
      return 'Linux Device';
    }

    return _getFallbackName();
  }

  Future<String> _getWebDeviceName() async {
    final info = await _deviceInfo.webBrowserInfo;
    return _formatBrowserName(info.browserName);
  }

  String _formatBrowserName(BrowserName browserName) {
    switch (browserName) {
      case BrowserName.chrome:
        return 'Chrome';
      case BrowserName.firefox:
        return 'Firefox';
      case BrowserName.safari:
        return 'Safari';
      case BrowserName.edge:
        return 'Edge';
      case BrowserName.opera:
        return 'Opera';
      case BrowserName.msie:
        return 'Internet Explorer';
      case BrowserName.samsungInternet:
        return 'Samsung Internet';
      case BrowserName.unknown:
        return 'Browser';
    }
  }

  String _formatMacModel(String model) {
    if (model.contains('MacBookPro')) return 'MacBook Pro';
    if (model.contains('MacBookAir')) return 'MacBook Air';
    if (model.contains('MacBook')) return 'MacBook';
    if (model.contains('Macmini')) return 'Mac mini';
    if (model.contains('MacPro')) return 'Mac Pro';
    if (model.contains('iMac')) return 'iMac';
    return 'Mac';
  }

  String _getFallbackName() {
    if (kIsWeb) return 'Browser';
    if (Platform.isIOS) return 'iPhone';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'Mac';
    if (Platform.isWindows) return 'Windows PC';
    if (Platform.isLinux) return 'Linux Device';
    return 'Device';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @visibleForTesting
  void clearCache() {
    _cachedDeviceName = null;
  }
}
