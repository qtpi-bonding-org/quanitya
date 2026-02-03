// lib/infra/services/haptic_service.dart

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Defines the contract for providing haptic feedback.
abstract class IHapticFeedbackService {
  /// Provides a light haptic feedback.
  Future<void> select();

  /// Provides a medium haptic feedback.
  Future<void> confirm();

  /// Provides a haptic feedback indicating a successful operation.
  Future<void> celebrate();

  /// Provides a haptic feedback indicating an error or failure.
  Future<void> error();
}

@LazySingleton(as: IHapticFeedbackService)
class HapticFeedbackService implements IHapticFeedbackService {
  @override
  Future<void> select() async {
    await HapticFeedback.lightImpact();
  }

  @override
  Future<void> confirm() async {
    await HapticFeedback.mediumImpact();
  }

  @override
  Future<void> celebrate() async {
    // A quick triple-tap feels more celebratory than a single thud.
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  @override
  Future<void> error() async {
    // Heavy impact is often used for errors.
    await HapticFeedback.heavyImpact();
  }
}
