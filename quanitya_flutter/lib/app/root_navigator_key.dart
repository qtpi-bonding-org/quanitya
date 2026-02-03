import 'package:flutter/material.dart';

/// Global key for the root navigator.
///
/// This allows services (like LoadingService, ToastFeedbackService) to access
/// the navigator's overlay from outside the widget tree for showing overlays
/// like loading indicators and toasts.
///
/// Must be passed to GoRouter.navigatorKey.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
