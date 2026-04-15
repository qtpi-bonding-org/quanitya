import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'platform_capability_service.dart';

@lazySingleton
class Haptics {
  final PlatformCapabilityService _capabilities;

  Haptics(this._capabilities);

  Future<void> light() async {
    if (!_capabilities.supportsHaptics) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (!_capabilities.supportsHaptics) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavy() async {
    if (!_capabilities.supportsHaptics) return;
    await HapticFeedback.heavyImpact();
  }
}
