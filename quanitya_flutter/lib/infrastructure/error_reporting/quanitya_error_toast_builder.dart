import 'package:flutter/material.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

import '../../design_system/primitives/quanitya_palette.dart';

/// Quanitya-styled error toast builder
/// 
/// Uses PostItToast from Quanitya design system with error styling
/// and action buttons for Send/Dismiss functionality.
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: palette.errorColor,
        content: Text(
          message,
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        action: SnackBarAction(
          label: 'Send Report',
          textColor: palette.textPrimary,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onSend();
          },
        ),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        onVisible: () {
          // Auto-dismiss after duration calls onDismiss
          Future.delayed(const Duration(seconds: 8), onDismiss);
        },
      ),
    );
  }
}