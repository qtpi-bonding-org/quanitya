import 'package:flutter/material.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../../support/extensions/color_extensions.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../support/utils/icon_resolver.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import '../../../../logic/templates/models/shared/field_validator.dart';

class TrackerCard extends StatelessWidget {
  final String title;
  final String? icon; // Format: "packname:iconname" (e.g., "material:fitness_center")
  final String? emoji; // Fallback emoji (e.g., "🏋️")
  final String? color; // Optional override color (hex)
  final TrackerTemplateModel? template; // Template data to check for defaults
  final VoidCallback? onIconTap; // Navigate to template editor
  final VoidCallback? onEdit;
  final VoidCallback? onQuickAction;

  const TrackerCard({
    super.key,
    required this.title,
    this.icon,
    this.emoji,
    this.color,
    this.template,
    this.onIconTap,
    this.onEdit,
    this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    // No-Card Design: Content sits directly on the page.
    // Alignment provides the structure.
    
    final quickActionWidget = QuanityaIconButton(
      icon: Icons.bolt,
      iconSize: AppSizes.iconMedium,
      tooltip: _canInstantLog()
          ? context.l10n.tooltipQuickEntry
          : context.l10n.tooltipQuickEntryUnavailable,
      onPressed: _canInstantLog() ? onQuickAction : null,
      // Uses interactableColor by default
    );

    final column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Icon (Big & Centered) - Priority: icon → emoji → default
        // Wrapped in GestureDetector for onIconTap (navigate to template editor)
        Center(
          child: Semantics(
            button: true,
            label: context.l10n.tooltipEditTemplate,
            child: GestureDetector(
              onTap: onIconTap,
              child: _buildIcon(context),
            ),
          ),
        ),

        VSpace.x05, // Small spacer between icon and title

        // 2. Title (Bold & Spaced) - Using AppPadding token
        Padding(
          padding: AppPadding.horizontalSingle,
          child: Text(
            title.toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              // REMOVED fontSize: 10 override to use AppSizes (labelSmall is size12)
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: context.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 3. Spacing (Component Breath)
        VSpace.x05, // Grouping breath

        // 4. Actions - Using QuanityaIconButton for consistent touch targets
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Edit - Using QuanityaIconButton with interactableColor
            QuanityaIconButton(
              icon: Icons.edit_outlined,
              iconSize: AppSizes.iconMedium,
              tooltip: context.l10n.tooltipCustomLog,
              onPressed: onEdit,
              // Uses interactableColor by default
            ),

            // Standard Breath between separate actions
            HSpace.x1,

            // Quick Action (Lightning) - Using QuanityaIconButton with interactableColor
            Opacity(
              opacity: _canInstantLog() ? 1.0 : 0.3,
              child: quickActionWidget,
            ),
          ],
        ),

        // Bottom cushion
        VSpace.x1,
      ],
    );

    return column;
  }

  Widget _buildIcon(BuildContext context) {
    // Parse the color from hex string if provided, fallback to Quanitya primary
    Color iconColor;
    if (color != null && color!.isNotEmpty) {
      iconColor = color!.toColor();
    } else {
      // Fallback to Quanitya's primary color
      iconColor = QuanityaPalette.primary.primaryColor;
    }
    
    // Priority: icon → emoji → default
    if (icon != null && icon!.contains(':')) {
      final iconData = _parseIconFromString(icon);
      if (iconData != null) {
        return Icon(
          iconData,
          size: AppSizes.fontMassive,
          color: iconColor,
        );
      }
    }
    
    // Fallback to emoji or default document icon
    if (emoji != null && emoji!.isNotEmpty) {
      return Text(
        emoji!,
        style: TextStyle(
          fontSize: AppSizes.fontMassive,
        ),
      );
    }
    
    // Final fallback to document icon
    return Icon(
      Icons.description,
      size: AppSizes.fontMassive,
      color: iconColor,
    );
  }

  /// Parse icon from "packname:iconname" format
  IconData? _parseIconFromString(String? iconString) {
    return IconResolver.resolve(iconString);
  }

  /// Check if all required fields have valid default values for instant logging.
  /// A template can be instant-logged only when every non-optional, non-deleted
  /// field has a defaultValue set.
  bool _canInstantLog() {
    if (template == null) return false;
    final activeFields = template!.fields.where((f) => !f.isDeleted);
    if (activeFields.isEmpty) return false;
    for (final field in activeFields) {
      final isOptional = field.validators.any(
        (v) => v.validatorType == ValidatorType.optional,
      );
      if (!isOptional && field.defaultValue == null) return false;
    }
    return true;
  }
}
