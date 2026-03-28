import 'package:flutter/material.dart';
import '../primitives/app_sizes.dart';
import '../../support/extensions/context_extensions.dart';
import '../primitives/quanitya_palette.dart';
import '../structures/column.dart';
import 'quanitya/general/quanitya_text_button.dart';

/// Dialog that shows custom content with Cancel/Confirm actions.
///
/// Same visual style as [QuanityaConfirmationDialog] but takes a [child]
/// widget instead of a message string. Used for import review, etc.
class QuanityaActionDialog extends StatelessWidget {
  static const _shadowColor = Color.fromRGBO(0, 0, 0, 0.15);
  final String title;
  final Widget child;
  final String? confirmText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const QuanityaActionDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onConfirm,
    this.confirmText,
    this.isDestructive = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required Widget child,
    required VoidCallback onConfirm,
    String? confirmText,
    bool isDestructive = false,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel:
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor:
          QuanityaPalette.primary.textPrimary.withValues(alpha: 0.54),
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
            child: QuanityaActionDialog(
              title: title,
              onConfirm: onConfirm,
              confirmText: confirmText,
              isDestructive: isDestructive,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: context.colors.backgroundPrimary,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            boxShadow: const [
              BoxShadow(
                color: _shadowColor,
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
              Flexible(child: child),
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
      ),
    );
  }
}
