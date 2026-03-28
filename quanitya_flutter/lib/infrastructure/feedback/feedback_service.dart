import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;
import '../config/debug_log.dart';

import '../../app/root_navigator_key.dart';
import '../../design_system/widgets/quanitya/general/post_it_toast.dart';

const _tag = 'infrastructure/feedback/feedback_service';

/// Toast feedback service using Quanitya palette colors and overlay.
@LazySingleton(as: cubit_ui_flow.IFeedbackService)
class ToastFeedbackService implements cubit_ui_flow.IFeedbackService {
  OverlayEntry? _overlayEntry;

  ToastFeedbackService();

  @override
  void show(cubit_ui_flow.FeedbackMessage message) {
    Future.microtask(() {
      try {
        // Remove existing toast if showing
        if (_overlayEntry != null) {
          Log.d(_tag, 'FeedbackService: Replacing existing toast.');
          _removeOverlay();
        }

        final overlayState = rootNavigatorKey.currentState?.overlay;
        if (overlayState == null) {
          Log.d(_tag, 'FeedbackService Error: Navigator overlay is null.');
          return;
        }

        final toastType = _mapMessageTypeToPostItType(message.type);

        _overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
            top: MediaQuery.of(context).viewPadding.top + 16.0,
            left: 16.0,
            right: 16.0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _removeOverlay,
                  onVerticalDragEnd: (_) => _removeOverlay(),
                  child: PostItToast(
                    message: message.message,
                    type: toastType,
                  ),
                ),
              ),
            ),
          ),
        );

        overlayState.insert(_overlayEntry!);
        Log.d(_tag, 'FeedbackService: Toast shown: "${message.message}"');

        // Auto-dismiss after duration
        final duration = message.type == cubit_ui_flow.MessageType.error
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3);
        
        Future.delayed(duration, _removeOverlay);
      } catch (e, stackTrace) {
        Log.d(_tag, 'FeedbackService show() failed: $e\n$stackTrace');
        _removeOverlay();
      }
    });
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      Log.d(_tag, 'FeedbackService: Toast removed.');
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  PostItType _mapMessageTypeToPostItType(cubit_ui_flow.MessageType type) {
    return switch (type) {
      cubit_ui_flow.MessageType.success => PostItType.success,
      cubit_ui_flow.MessageType.error => PostItType.error,
      cubit_ui_flow.MessageType.warning => PostItType.warning,
      cubit_ui_flow.MessageType.info => PostItType.info,
      cubit_ui_flow.MessageType.loading => PostItType.info,
    };
  }
}
