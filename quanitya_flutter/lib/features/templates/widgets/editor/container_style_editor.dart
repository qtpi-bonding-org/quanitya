import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';

import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/widgets/styled_field_container.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../support/extensions/color_extensions.dart';
import '../../../../logic/templates/enums/ai/template_preset.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';

/// Widget for selecting the container style preset for a template.
class ContainerStyleEditor extends StatelessWidget {
  const ContainerStyleEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      builder: (context, state) {
        final selectedContainerStyle = state.aesthetics?.containerStyle;

        // Get accent color for preview
        final accentHex = state.aesthetics?.palette.accents.firstOrNull ?? '#006280';
        final accentColor = HexColorExtension(accentHex).toColor();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Text(
              context.l10n.templateContainerStyleTitle,
              style: context.text.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x1,
            // Description
            Text(
              context.l10n.templateContainerStyleDescription,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            VSpace.x2,
            // Preset grid
            LayoutGroup.grid(
              minItemWidth: 12,
              children: TemplateContainerStyle.values.map((style) {
                final isSelected = style == selectedContainerStyle;
                return _PresetCard(
                  style: style,
                  accentColor: accentColor,
                  isSelected: isSelected,
                  onTap: () => context
                      .read<TemplateEditorCubit>()
                      .updateContainerStyle(style),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

/// Card widget for displaying a single container style option.
class _PresetCard extends StatelessWidget {
  final TemplateContainerStyle style;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.style,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 72,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? accentColor : context.colors.textSecondary.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          color: isSelected ? accentColor.withValues(alpha: 0.05) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mini preview of the style geometry
            _PresetMiniPreview(style: style, accentColor: accentColor),
            VSpace.x05,
            Text(
              style.displayName,
              style: context.text.labelSmall?.copyWith(
                color: isSelected ? accentColor : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini preview showing the container style's geometry.
class _PresetMiniPreview extends StatelessWidget {
  final TemplateContainerStyle style;
  final Color accentColor;

  const _PresetMiniPreview({
    required this.style,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 24,
      child: StyledFieldContainer(
        preset: style,
        accentColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.textSecondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
        ),
      ),
    );
  }
}
