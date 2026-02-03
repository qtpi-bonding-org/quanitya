import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;

import '../../app/root_navigator_key.dart';

/// Loading service using overlay with circular progress indicator.
@LazySingleton(as: cubit_ui_flow.ILoadingService)
class LoadingService implements cubit_ui_flow.ILoadingService {
  OverlayEntry? _overlayEntry;

  LoadingService();

  @override
  void show() {
    Future.microtask(() {
      try {
        if (_overlayEntry != null) {
          debugPrint('⚠️ LoadingService: Overlay already shown. Skipping.');
          return;
        }

        final overlayState = rootNavigatorKey.currentState?.overlay;
        if (overlayState == null) {
          debugPrint('❌ LoadingService Error: Navigator overlay is null.');
          return;
        }

        _overlayEntry = OverlayEntry(
          builder: (context) => const Stack(
            children: [
              ModalBarrier(dismissible: false, color: Colors.black38),
              Center(child: CircularProgressIndicator(color: Colors.white)),
            ],
          ),
        );

        overlayState.insert(_overlayEntry!);
        debugPrint('✅ LoadingService: Overlay inserted.');
      } catch (e, stackTrace) {
        debugPrint('❌ LoadingService show() failed: $e\n$stackTrace');
        _overlayEntry = null;
      }
    });
  }

  @override
  void hide() {
    Future.microtask(() {
      try {
        if (_overlayEntry != null) {
          _overlayEntry!.remove();
          _overlayEntry = null;
          debugPrint('✅ LoadingService: Overlay removed.');
        }
      } catch (e) {
        debugPrint('LoadingService hide() failed safely. Error: $e');
      }
    });
  }

  bool get isLoading => _overlayEntry != null;
}