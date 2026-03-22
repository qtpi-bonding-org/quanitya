import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:get_it/get_it.dart';

import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../support/extensions/color_extensions.dart';
import '../../../../support/utils/icon_resolver.dart';
import '../../../../infrastructure/fonts/font_preloader_service.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';

/// Widget for editing the template's quick-access icon.
///
/// Displays a preview bubble (accent-colored circle) with the selected icon
/// and the template name rendered in the chosen title font. Tapping opens
/// the [flutter_iconpicker] dialog so the user can pick a new icon.
class TemplateIconEditor extends StatelessWidget {
  const TemplateIconEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      buildWhen: (p, c) =>
          p.aesthetics != c.aesthetics || p.templateName != c.templateName,
      builder: (context, state) {
        final iconString = state.aesthetics?.icon;
        final iconData = _parseIconFromString(iconString);

        // Get accent color from aesthetics
        final accentHexStr = state.aesthetics?.palette.accents.firstOrNull;
        final accentColor = accentHexStr != null
            ? HexColorExtension(accentHexStr).toColor()
            : context.colors.primaryColor;

        // Get title font from aesthetics
        final titleFont = state.aesthetics?.fontConfig.titleFontFamily;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section title — titleMedium (16px, heavy, Atkinson)
            Text(
              context.l10n.quickAccessIconLabel,
              style: context.text.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x1,
            // Description — bodyMedium (14px, Noto Sans), grey
            Text(
              context.l10n.quickAccessIconDescription,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            VSpace.x2,
            // Icon and name preview (as it will appear on home page)
            Center(
              child: Semantics(
                button: true,
                label: context.l10n.accessibilityChangeTemplateIcon,
                child: GestureDetector(
                  onTap: () => _showIconPicker(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon bubble with template's accent color.
                      // AppSizes.iconXLarge (48dp) satisfies the minimum touch
                      // target requirement per design system standards.
                      Container(
                        width: AppSizes.iconXLarge,
                        height: AppSizes.iconXLarge,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor,
                            width: AppSizes.borderWidthThick,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          iconData,
                          size: AppSizes.iconLarge,
                          color: accentColor,
                        ),
                      ),
                      VSpace.x1,
                      // Show template name below icon with title font
                      Text(
                        state.templateName.isEmpty
                            ? context.l10n.templateNamePlaceholder
                            : state.templateName,
                        style: _getTitleStyle(titleFont, context).copyWith(
                          color: state.templateName.isEmpty
                              ? context.colors.textSecondary.withValues(alpha: 0.5)
                              : context.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Get title style with Google Font if specified.
  TextStyle _getTitleStyle(String? fontName, BuildContext context) {
    final baseStyle = context.text.bodyLarge ?? const TextStyle();

    if (fontName == null || fontName.isEmpty) {
      return baseStyle;
    }

    final fontPreloader = GetIt.I<FontPreloaderService>();
    return fontPreloader.getTextStyle(
      fontName,
      fontSize: baseStyle.fontSize,
    );
  }

  /// Parse icon from "packname:iconname" format.
  IconData _parseIconFromString(String? iconString) {
    return IconResolver.resolve(iconString) ?? Icons.description;
  }

  Future<void> _showIconPicker(BuildContext context) async {
    final icon = await showIconPicker(
      context,
      configuration: SinglePickerConfiguration(
        iconPackModes: [IconPack.material],
        showSearchBar: true,
        showTooltips: true,
        adaptiveDialog: true,
      ),
    );

    if (icon != null && context.mounted) {
      // Format: "packname:iconname"
      final packName = icon.pack.name;
      final iconName = icon.name;
      final iconString = '$packName:$iconName';

      debugPrint('Icon picked:');
      debugPrint('  pack.name: $packName');
      debugPrint('  icon.name: $iconName');
      debugPrint('  iconString: $iconString');

      context.read<TemplateEditorCubit>().updateTemplateIcon(iconString);
    }
  }
}
