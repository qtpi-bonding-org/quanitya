import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';

/// Dynamic dropdown selector for field names based on template context.
///
/// Shows actual field names from the current template instead of hardcoded options.
class DynamicFieldSelector extends StatelessWidget {
  final List<String> availableFields;
  final String? selectedField;
  final ValueChanged<String> onFieldChanged;
  final String? errorText;
  
  const DynamicFieldSelector({
    super.key,
    required this.availableFields,
    this.selectedField,
    required this.onFieldChanged,
    this.errorText,
  });
  
  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    
    if (availableFields.isEmpty) {
      return _buildEmptyState(context, palette);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Field Name',
          style: context.text.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
        VSpace.x05,
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: errorText != null ? palette.errorColor : palette.textSecondary.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: selectedField,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: Text(
              'Select field to extract',
              style: context.text.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            items: availableFields.map((fieldName) {
              return DropdownMenuItem<String>(
                value: fieldName,
                child: Row(
                  children: [
                    Icon(
                      Icons.data_array,
                      size: 16,
                      color: palette.textSecondary,
                    ),
                    HSpace.x1,
                    Text(
                      fieldName,
                      style: context.text.bodyMedium?.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onFieldChanged(value);
              }
            },
            dropdownColor: palette.backgroundPrimary,
            style: context.text.bodyMedium?.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ),
        if (errorText != null) ...[
          VSpace.x05,
          Text(
            errorText!,
            style: context.text.bodySmall?.copyWith(
              color: palette.errorColor,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context, dynamic palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Field Name',
          style: context.text.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
        VSpace.x05,
        Container(
          padding: AppPadding.allSingle,
          decoration: BoxDecoration(
            border: Border.all(
              color: palette.textSecondary.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            color: palette.backgroundPrimary.withValues(alpha: 0.5),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: palette.textSecondary,
              ),
              HSpace.x1,
              Expanded(
                child: Text(
                  'No numeric fields available in this template',
                  style: context.text.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}