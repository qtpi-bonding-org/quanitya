import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Field selector widget for AI suggestions
class AiFieldSelector extends StatelessWidget {
  final List<String> availableFields;
  final String? selectedField;
  final ValueChanged<String?> onFieldChanged;
  final bool enabled;

  const AiFieldSelector({
    super.key,
    required this.availableFields,
    required this.selectedField,
    required this.onFieldChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (availableFields.isEmpty) {
      return Container(
        padding: AppPadding.allDouble,
        decoration: BoxDecoration(
          color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(
            color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: QuanityaPalette.primary.textSecondary,
            ),
            HSpace.x1,
            Expanded(
              child: Text(
                'No numeric fields available for analysis',
                style: context.text.bodySmall?.copyWith(
                  color: QuanityaPalette.primary.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Field to Analyze',
          style: context.text.bodySmall?.copyWith(
            color: QuanityaPalette.primary.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        VSpace.x05,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled 
                ? QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3)
                : QuanityaPalette.primary.textSecondary.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            color: enabled 
              ? QuanityaPalette.primary.backgroundPrimary
              : QuanityaPalette.primary.textSecondary.withValues(alpha: 0.05),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedField,
              hint: Text(
                'Choose a field...',
                style: context.text.bodyMedium?.copyWith(
                  color: QuanityaPalette.primary.textSecondary,
                ),
              ),
              isExpanded: true,
              onChanged: enabled ? onFieldChanged : null,
              items: availableFields.map((field) {
                return DropdownMenuItem<String>(
                  value: field,
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 16,
                        color: QuanityaPalette.primary.interactableColor,
                      ),
                      HSpace.x05,
                      Expanded(
                        child: Text(
                          field,
                          style: context.text.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}