import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';

import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../infrastructure/fonts/font_preloader_service.dart';
import '../../../../logic/templates/enums/ai/allowed_font.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';

/// Widget for editing the typography settings (title and body fonts) of a template.
class TypographyEditor extends StatelessWidget {
  const TypographyEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      buildWhen: (p, c) => p.aesthetics != c.aesthetics,
      builder: (context, state) {
        final titleFont =
            state.aesthetics?.fontConfig.titleFontFamily ??
            'Atkinson Hyperlegible Mono';
        final bodyFont =
            state.aesthetics?.fontConfig.bodyFontFamily ?? 'Noto Sans Mono';

        final allFonts = AllowedFont.allFontNames;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title - titleMedium (16px, heavy, Atkinson)
            Text(
              context.l10n.typographySection,
              style: context.text.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x2,
            LayoutGroup.row(
              minChildWidth: 18,
              children: [
                _buildFontDropdown(
                  context,
                  context.l10n.fontTitleLabel,
                  allFonts,
                  titleFont,
                  (val) =>
                      context.read<TemplateEditorCubit>().updateTitleFont(val),
                ),
                HSpace.x2,
                _buildFontDropdown(
                  context,
                  context.l10n.fontBodyLabel,
                  allFonts,
                  bodyFont,
                  (val) =>
                      context.read<TemplateEditorCubit>().updateBodyFont(val),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildFontDropdown(
    BuildContext context,
    String label,
    List<String> fonts,
    String selectedFont,
    ValueChanged<String> onChanged,
  ) {
    // Ensure selected font is in the list
    final effectiveSelected =
        fonts.contains(selectedFont) ? selectedFont : fonts.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label - bodyMedium (14px, Noto Sans), grey
        Text(
          label,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        VSpace.x1,
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: effectiveSelected,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: context.colors.interactableColor,
            ),
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textPrimary,
            ),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
            items: fonts
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(f, style: _getGoogleFontStyle(context, f)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Get TextStyle with Google Font applied via [FontPreloaderService].
  TextStyle _getGoogleFontStyle(BuildContext context, String fontName) {
    final fontPreloader = context.read<FontPreloaderService>();
    return fontPreloader.getTextStyle(fontName);
  }
}
