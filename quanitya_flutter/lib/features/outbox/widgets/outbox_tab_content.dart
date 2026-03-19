import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Generic layout shell for outbox tabs.
///
/// Provides a consistent structure: optional banner at top,
/// expanded content area in the middle, and optional bottom actions.
/// Each outbox tab (Feedback, Analytics, Errors) plugs its specific
/// widgets into these slots.
class OutboxTabContent extends StatelessWidget {
  /// The main content area — fills available space.
  final Widget content;

  /// Optional widget pinned to the bottom (e.g. action buttons).
  final Widget? bottomAction;

  /// Optional empty-state widget shown instead of [content] when [isEmpty] is true.
  final Widget? emptyState;

  /// When true, shows [emptyState] instead of the normal layout.
  final bool isEmpty;

  /// When true, shows a loading indicator instead of content.
  final bool isLoading;

  const OutboxTabContent({
    super.key,
    required this.content,
    this.bottomAction,
    this.emptyState,
    this.isEmpty = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isEmpty && emptyState != null) {
      return emptyState!;
    }

    return Stack(
      children: [
        content,
        if (bottomAction != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: bottomAction!,
          ),
      ],
    );
  }
}

/// Reusable privacy banner used across outbox tabs.
class OutboxPrivacyBanner extends StatelessWidget {
  final String text;

  const OutboxPrivacyBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.allDouble,
      child: Row(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: AppSizes.iconMedium,
            color: context.colors.infoColor,
          ),
          HSpace.x2,
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable empty state for outbox tabs.
class OutboxEmptyState extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String description;

  const OutboxEmptyState({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppSizes.iconLarge * 2,
              color: iconColor ?? context.colors.textSecondary,
            ),
            VSpace.x4,
            Text(
              title,
              style: context.text.headlineMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            VSpace.x2,
            Text(
              description,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
