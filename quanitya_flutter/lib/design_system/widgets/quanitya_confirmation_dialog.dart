import 'package:flutter/material.dart';
import '../primitives/app_sizes.dart';
import '../../support/extensions/context_extensions.dart';
import '../primitives/quanitya_palette.dart';
import '../structures/column.dart';
import 'quanitya/general/quanitya_text_button.dart';

class QuanityaConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const QuanityaConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText,
    this.isDestructive = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String? confirmText,
    bool isDestructive = false,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel:
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: QuanityaPalette.primary.textPrimary.withValues(alpha: 0.54),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSizes.space * 2,
              right: AppSizes.space * 2,
              bottom: MediaQuery.of(context).viewPadding.bottom +
                  AppSizes.space * 3,
            ),
            child: QuanityaConfirmationDialog(
              title: title,
              message: message,
              onConfirm: onConfirm,
              confirmText: confirmText,
              isDestructive: isDestructive,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: context.colors.backgroundPrimary,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.15),
              offset: Offset(2, 3),
              blurRadius: 4,
            ),
          ],
        ),
        padding: EdgeInsets.all(AppSizes.space * 2),
        child: QuanityaColumn(
          crossAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: context.text.headlineMedium),
            Text(message, style: context.text.bodyLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                QuanityaTextButton(
                  text: context.l10n.actionCancel,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                QuanityaTextButton(
                  text: confirmText ?? context.l10n.confirm,
                  isDestructive: isDestructive,
                  onPressed: () {
                    onConfirm();
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
