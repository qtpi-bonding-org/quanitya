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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.backgroundPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      title: Text(title, style: context.text.headlineMedium), // 24px
      content: SingleChildScrollView(
        child: QuanityaColumn(
          crossAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: context.text.bodyLarge), // 16px
          ],
        ),
      ),
      actions: [
        QuanityaTextButton(
          text: context.l10n.actionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        QuanityaTextButton(
          text: confirmText ?? context.l10n.confirm,
          isDestructive: isDestructive,
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
