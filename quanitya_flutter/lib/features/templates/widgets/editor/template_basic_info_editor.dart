import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:get_it/get_it.dart';

import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/widgets/styled_field_container.dart';
import '../../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../../support/extensions/color_extensions.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../support/utils/icon_resolver.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../infrastructure/fonts/font_preloader_service.dart';
import '../../../../logic/templates/enums/ai/template_preset.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';
import '../../../../design_system/widgets/quanitya_text_field.dart';

/// Widget for editing basic template information (name, description, aesthetics)
class TemplateBasicInfoEditor extends StatefulWidget {
  const TemplateBasicInfoEditor({super.key});

  @override
  State<TemplateBasicInfoEditor> createState() =>
      _TemplateBasicInfoEditorState();
}

class _TemplateBasicInfoEditorState extends State<TemplateBasicInfoEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final state = context.read<TemplateEditorCubit>().state;
    _nameController = TextEditingController(text: state.templateName);
    _descriptionController = TextEditingController(
      text: state.templateDescription,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TemplateEditorCubit, TemplateEditorState>(
      listenWhen: (previous, current) =>
          previous.templateName != current.templateName ||
          previous.templateDescription != current.templateDescription,
      listener: (context, state) {
        if (_nameController.text != state.templateName) {
          _nameController.text = state.templateName;
        }
        if (_descriptionController.text != state.templateDescription) {
          _descriptionController.text = state.templateDescription;
        }
      },
      child: QuanityaColumn(
        crossAlignment: CrossAxisAlignment.stretch,
        children: [
          // Color Palette Selector
          BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
            builder: (context, state) => _buildColorSelector(context, state),
          ),

          VSpace.x3,

          // Typography
          _buildTypographySelector(context),

          VSpace.x3,

          // Container Style Preset
          _buildPresetSelector(context),

          VSpace.x3,

          // Template Icon & Source Badge
          // Icon Selector
          _buildIconSelector(context),

          VSpace.x3,

          // Template Name - section title style (titleMedium = 16px, heavy)
          Text(
            context.l10n.templateNameLabel,
            style: context.text.titleMedium?.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          VSpace.x1,
          QuanityaTextField(
            controller: _nameController,
            style: context.text.bodyLarge,
            hintText: context.l10n.templateNameHint,
            onChanged: (value) =>
                context.read<TemplateEditorCubit>().updateTemplateName(value),
          ),

          VSpace.x3,

          // Template Description - section title style
          Text(
            context.l10n.templateDescriptionLabel,
            style: context.text.titleMedium?.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          VSpace.x1,
          QuanityaTextField(
            controller: _descriptionController,
            maxLines: 2,
            hintText: context.l10n.templateDescriptionHint,
            onChanged: (value) => context
                .read<TemplateEditorCubit>()
                .updateTemplateDescription(value),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSelector(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
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
            // Section title - titleMedium (16px, heavy, Atkinson)
            Text(
              context.l10n.quickAccessIconLabel,
              style: context.text.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            VSpace.x1,
            // Description - bodyMedium (14px, Noto Sans), grey
            Text(
              context.l10n.quickAccessIconDescription,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            VSpace.x2,
            // Icon and name preview (as it will appear on home page)
            Center(
              child: GestureDetector(
                onTap: () => _showIconPicker(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon bubble with template's accent color
                    Container(
                      width: AppSizes.iconXLarge,
                      height: AppSizes.iconXLarge,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor,
                          width: 2,
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
          ],
        );
      },
    );
  }
  
  /// Get title style with Google Font if specified
  TextStyle _getTitleStyle(String? fontName, BuildContext context) {
    final baseStyle = context.text.bodyLarge ?? const TextStyle();
    
    if (fontName == null || fontName.isEmpty) {
      return baseStyle;
    }
    
    // Use font preloader service for better font handling
    final fontPreloader = GetIt.I<FontPreloaderService>();
    return fontPreloader.getTextStyle(
      fontName,
      fontSize: baseStyle.fontSize,
    );
  }

  /// Parse icon from "packname:iconname" format
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
      
      debugPrint('🎯 Icon picked:');
      debugPrint('🎯   pack.name: $packName');
      debugPrint('🎯   icon.name: $iconName');
      debugPrint('🎯   iconString: $iconString');
      
      context.read<TemplateEditorCubit>().updateTemplateIcon(iconString);
    }
  }
  
  Widget _buildTypographySelector(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      builder: (context, state) {
        final titleFont = state.aesthetics?.fontConfig.titleFontFamily ?? 'Atkinson Hyperlegible Mono';
        final bodyFont = state.aesthetics?.fontConfig.bodyFontFamily ?? 'Noto Sans Mono';
        
        // All 16 fonts available for both title and body
        const allFonts = [
          // Defaults
          'Atkinson Hyperlegible Mono',  // Accessible, clean
          'Noto Sans Mono',              // Universal, clean
          // Expressive / Display
          'Playfair Display',       // Elegant, feminine, editorial
          'Bebas Neue',             // Bold, sporty, masculine
          'Pacifico',               // Playful, casual, fun
          'Cormorant Garamond',     // Sophisticated, literary
          'Righteous',              // Retro, groovy, creative
          'Quicksand',              // Soft, friendly, wellness
          'Space Grotesk',          // Tech, modern, minimal
          // Readable / Body-friendly
          'Lora',                   // Warm, readable, journaling
          'Inter',                  // Modern, UI-focused, tech
          'Nunito',                 // Rounded, friendly, approachable
          'Source Serif 4',         // Classic, professional
          'Karla',                  // Geometric, contemporary
          'Cabin',                  // Humanist, balanced
          'Space Mono',             // Monospace, raw data, journaling
        ];
        
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
                  (val) => context.read<TemplateEditorCubit>().updateTitleFont(val),
                ),
                HSpace.x2,
                _buildFontDropdown(
                  context,
                  context.l10n.fontBodyLabel,
                  allFonts,
                  bodyFont,
                  (val) => context.read<TemplateEditorCubit>().updateBodyFont(val),
                ),
              ],
            )
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
    final effectiveSelected = fonts.contains(selectedFont) ? selectedFont : fonts.first;
    
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
            items: fonts.map((f) => DropdownMenuItem(
              value: f, 
              child: Text(f, style: _getGoogleFontStyle(f)),
            )).toList(),
          ),
        ),
      ],
    );
  }

  /// Get TextStyle with Google Font applied
  TextStyle _getGoogleFontStyle(String fontName) {
    // Use font preloader service for better font handling
    final fontPreloader = GetIt.I<FontPreloaderService>();
    return fontPreloader.getTextStyle(fontName);
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
              width: 80,
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
              width: 80,
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

  Widget _buildPaletteCircle(BuildContext context, Color color, Function(Color) onColorChanged) {
    return GestureDetector(
      onTap: () => _showColorPicker(context, color, onColorChanged),
      child: Container(
        width: AppSizes.iconLarge,
        height: AppSizes.iconLarge,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.2)),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, Color currentColor, Function(Color) onColorChanged) {
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
              child: TextButton(
                child: Text(context.l10n.selectAction),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSelector(BuildContext context) {
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
