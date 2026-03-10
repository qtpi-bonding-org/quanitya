import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

import '../../design_system/primitives/quanitya_fonts.dart';
import '../../design_system/primitives/quanitya_palette.dart';
import '../../design_system/primitives/app_sizes.dart';
import '../../design_system/widgets/quanitya/general/post_it_toast.dart';

/// Quanitya-styled error toast builder
///
/// Uses PostItToast from Quanitya design system with error styling
/// and action buttons for Send/Dismiss functionality.
/// Displays as a top-positioned overlay instead of a bottom SnackBar.
class QuanityaErrorToastBuilder extends ErrorToastBuilder {
  const QuanityaErrorToastBuilder();

  @override
  void show(
    BuildContext context,
    String message, {
    required VoidCallback onDismiss,
    required VoidCallback onSend,
  }) {
    final palette = QuanityaPalette.primary;
    OverlayEntry? overlayEntry;

    void removeOverlay() {
      if (overlayEntry != null) {
        overlayEntry!.remove();
        overlayEntry = null;
        onDismiss();
      }
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 16.0,
        left: 16.0,
        right: 16.0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: removeOverlay,
              onVerticalDragEnd: (_) => removeOverlay(),
              child: PostItToast(
                message: message,
                type: PostItType.error,
                action: GestureDetector(
                  onTap: () {
                    removeOverlay();
                    onSend();
                  },
                  child: Text(
                    'Send Report',
                    style: TextStyle(
                      fontFamily: QuanityaFonts.headerFamily,
                      fontSize: AppSizes.fontSmall,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry!);

    // Auto-dismiss after 8 seconds
    Future.delayed(const Duration(seconds: 8), removeOverlay);
  }
}
