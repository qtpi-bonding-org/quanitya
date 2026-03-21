import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../support/extensions/color_extensions.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';

/// Widget for editing the color palette of a template (accent and tone colors).
class ColorPaletteEditor extends StatelessWidget {
  // Label column width — component-specific; no matching AppSizes token.
  static const _labelColumnWidth = 80.0;
  const ColorPaletteEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      buildWhen: (p, c) => p.aesthetics != c.aesthetics,
      builder: (context, state) => _buildColorSelector(context, state),
    );
  }

  Widget _buildColorSelector(BuildContext context, TemplateEditorState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title - titleMedium (16px, heavy, Atkinson)
        Text(
          context.l10n.colorThemeSection,
          style: context.text.titleMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        VSpace.x2,

        // Accents Row - interactive element colors
        Row(
          children: [
            SizedBox(
              width: _labelColumnWidth,
              child: Text(
                context.l10n.templateAccentLabel,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            ...List.generate(
              state.aesthetics?.palette.accents.length ?? 0,
              (index) {
                final hexColor = state.aesthetics!.palette.accents[index];
                final color = HexColorExtension(hexColor).toColor();

                return Padding(
                  padding:
                      EdgeInsets.only(right: index < 2 ? AppSizes.space * 2 : 0),
                  child: _buildPaletteCircle(
                    context,
                    color,
                    (newColor) {
                      final hex =
                          '#${newColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                      context
                          .read<TemplateEditorCubit>()
                          .updateAccentColor(index, hex);
                    },
                  ),
                );
              },
            ),
          ],
        ),

        VSpace.x2,

        // Tones Row - text variation colors
        Row(
          children: [
            SizedBox(
              width: _labelColumnWidth,
              child: Text(
                context.l10n.templateToneLabel,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            ...List.generate(
              state.aesthetics?.palette.tones.length ?? 0,
              (index) {
                final hexColor = state.aesthetics!.palette.tones[index];
                final color = HexColorExtension(hexColor).toColor();

                return Padding(
                  padding:
                      EdgeInsets.only(right: index < 1 ? AppSizes.space * 2 : 0),
                  child: _buildPaletteCircle(
                    context,
                    color,
                    (newColor) {
                      final hex =
                          '#${newColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                      context
                          .read<TemplateEditorCubit>()
                          .updateToneColor(index, hex);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaletteCircle(
    BuildContext context,
    Color color,
    Function(Color) onColorChanged,
  ) {
    return Semantics(
      button: true,
      label: 'Change color',
      child: GestureDetector(
        onTap: () => _showColorPicker(context, color, onColorChanged),
        child: SizedBox(
          width: AppSizes.buttonHeight,
          height: AppSizes.buttonHeight,
          child: Center(
            child: Container(
              width: AppSizes.iconLarge,
              height: AppSizes.iconLarge,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    LooseInsertSheet.show(
      context: context,
      title: context.l10n.pickColorTitle,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.7,
            ),
            VSpace.x2,
            Align(
              alignment: Alignment.centerRight,
              child: QuanityaTextButton(
                text: context.l10n.selectAction,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
