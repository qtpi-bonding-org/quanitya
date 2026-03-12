import 'package:flutter/material.dart';
import '../../../primitives/app_sizes.dart';
import '../../../primitives/quanitya_palette.dart';
import '../../../../support/extensions/context_extensions.dart';

/// Standardized bottom sheet wrapper — the "loose insert" pattern.
///
/// Every form/input surface uses this consistent presentation:
/// a draggable sheet with handle bar, optional title, and content area.
class LooseInsertSheet extends StatelessWidget {
  final String? title;
  final Widget child;

  const LooseInsertSheet({
    super.key,
    this.title,
    required this.child,
  });

  /// Show a modal bottom sheet using the LooseInsertSheet wrapper.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LooseInsertSheet(
        title: title,
        child: builder(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.colors.backgroundPrimary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusMedium),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: EdgeInsets.only(top: AppSizes.space),
            child: Center(
              child: Container(
                width: AppSizes.space * 5,
                height: AppSizes.space * 0.5,
                decoration: BoxDecoration(
                  color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSizes.space * 0.25),
                ),
              ),
            ),
          ),
          // Optional title
          if (title != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.space * 2,
                  vertical: AppSizes.space,
                ),
                child: Text(
                  title!,
                  style: context.text.headlineMedium,
                ),
              ),
            ),
          // Content
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSizes.space * 2,
                right: AppSizes.space * 2,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSizes.space * 2,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
