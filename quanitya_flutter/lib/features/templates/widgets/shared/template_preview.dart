import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:get_it/get_it.dart';

import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/styled_field_container.dart';
import '../../../../support/extensions/color_extensions.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../logic/templates/enums/ai/allowed_font.dart';
import '../../../../logic/templates/enums/ai/template_preset.dart';
import '../../../../logic/templates/models/shared/model_runtime_converter.dart';
import '../../../../logic/templates/models/shared/template_aesthetics.dart';
import '../../../../logic/templates/models/shared/template_field.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import '../../../../logic/templates/services/shared/default_value_handler.dart';
import '../../../../logic/templates/services/shared/dynamic_field_builder.dart';
import '../../../../design_system/widgets/quanitya/general/zen_paper_background.dart';
import '../../../../infrastructure/fonts/font_preloader_service.dart';
import '../../../../support/utils/icon_resolver.dart';

/// Unified template preview widget that works with any template source.
///
/// Shows: icon/emoji centered, template name, interactive fields, action buttons.
/// Uses aesthetics for colors and fonts throughout.
class TemplatePreview extends StatefulWidget {
  final TrackerTemplateModel template;
  final TemplateAestheticsModel? aesthetics;
  final List<TemplatePreviewAction> actions;
  final Map<String, dynamic>? initialValues;
  final ValueChanged<Map<String, dynamic>>? onValuesChanged;

  const TemplatePreview({
    super.key,
    required this.template,
    this.aesthetics,
    this.actions = const [],
    this.initialValues,
    this.onValuesChanged,
  });

  /// Factory for editor context
  factory TemplatePreview.editor({
    Key? key,
    required TrackerTemplateModel template,
    TemplateAestheticsModel? aesthetics,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    Map<String, dynamic>? initialValues,
    ValueChanged<Map<String, dynamic>>? onValuesChanged,
  }) {
    return TemplatePreview(
      key: key,
      template: template,
      aesthetics: aesthetics,
      initialValues: initialValues,
      onValuesChanged: onValuesChanged,
      actions: [
        TemplatePreviewAction.secondary(
          label: 'Edit',
          icon: Icons.edit,
          onPressed: onEdit,
        ),
        TemplatePreviewAction.primary(
          label: 'Save Template',
          icon: Icons.save,
          onPressed: onSave,
        ),
      ],
    );
  }

  /// Factory for AI generation context
  factory TemplatePreview.aiGenerated({
    Key? key,
    required TrackerTemplateModel template,
    required TemplateAestheticsModel aesthetics,
    required VoidCallback onSave,
    VoidCallback? onDiscard,
    Map<String, dynamic>? initialValues,
    ValueChanged<Map<String, dynamic>>? onValuesChanged,
  }) {
    return TemplatePreview(
      key: key,
      template: template,
      aesthetics: aesthetics,
      initialValues: initialValues,
      onValuesChanged: onValuesChanged,
      actions: [
        if (onDiscard != null)
          TemplatePreviewAction.secondary(
            label: 'Discard',
            icon: Icons.close,
            onPressed: onDiscard,
          ),
        TemplatePreviewAction.primary(
          label: 'Save Template',
          icon: Icons.save,
          onPressed: onSave,
        ),
      ],
    );
  }

  /// Factory for import context
  factory TemplatePreview.imported({
    Key? key,
    required TrackerTemplateModel template,
    TemplateAestheticsModel? aesthetics,
    required VoidCallback onImport,
    VoidCallback? onCancel,
    Map<String, dynamic>? initialValues,
    ValueChanged<Map<String, dynamic>>? onValuesChanged,
  }) {
    return TemplatePreview(
      key: key,
      template: template,
      aesthetics: aesthetics,
      initialValues: initialValues,
      onValuesChanged: onValuesChanged,
      actions: [
        if (onCancel != null)
          TemplatePreviewAction.secondary(
            label: 'Cancel',
            icon: Icons.close,
            onPressed: onCancel,
          ),
        TemplatePreviewAction.primary(
          label: 'Import Template',
          icon: Icons.download,
          onPressed: onImport,
        ),
      ],
    );
  }

  @override
  State<TemplatePreview> createState() => _TemplatePreviewState();
}

class _TemplatePreviewState extends State<TemplatePreview> {
  late final Map<String, dynamic> _previewValues;
  late final ModelRuntimeConverter _converter;
  late final IColorPalette _palette;

  // Resolved accent colors from aesthetics
  Color? _accent1;
  Color? _accent2;
  Color? _tone1;
  Color? _tone2;

  @override
  void initState() {
    super.initState();
    _converter = ModelRuntimeConverter();
    _palette = widget.aesthetics != null
        ? _converter.toColorPalette(widget.aesthetics!.palette)
        : _getDefaultPalette();

    _resolveAestheticsColors();
    _previewValues = Map<String, dynamic>.from(widget.initialValues ?? {});
    _initializeDefaultValues();
  }

  void _resolveAestheticsColors() {
    if (widget.aesthetics == null) return;

    final accents = widget.aesthetics!.palette.accents;
    final tones = widget.aesthetics!.palette.tones;

    if (accents.isNotEmpty) _accent1 = accents[0].toColor();
    if (accents.length > 1) _accent2 = accents[1].toColor();
    if (tones.isNotEmpty) _tone1 = tones[0].toColor();
    if (tones.length > 1) _tone2 = tones[1].toColor();
  }

  IColorPalette _getDefaultPalette() {
    // Use QuanityaPalette colors for default palette
    return AppColorPalette.enumerated(
      colors: [
        QuanityaPalette.primary.backgroundPrimary, // Washi White
        QuanityaPalette.primary.primaryColor, // Teal
        const Color(0xFFF57C00), // Orange (not in palette)
      ],
      neutrals: [
        QuanityaPalette.primary.textPrimary, // Sumi Black
        const Color(0xFFF5F5F5), // Light grey (not in palette)
      ],
    );
  }

  void _initializeDefaultValues() {
    final handler = GetIt.I<DefaultValueHandler>();
    for (final field in widget.template.fields) {
      if (!_previewValues.containsKey(field.id)) {
        _previewValues[field.id] = handler.resolveDefault(field);
      }
    }
  }

  void _updatePreviewValue(String fieldId, dynamic value) {
    setState(() {
      _previewValues[fieldId] = value;
    });
    widget.onValuesChanged?.call(_previewValues);
  }

  // Colors
  Color get _accentColor => _accent1 ?? context.colors.interactableColor;
  Color get _secondaryColor => _tone1 ?? context.colors.textSecondary;

  /// Resolves widget colors using aesthetics color mappings.
  ///
  /// Uses the colorMappings from aesthetics to get widget-specific colors.
  /// Falls back to manual color assignment if no mapping exists.
  Map<String, Color> _resolveWidgetColors(String uiElement) {
    final mapping = widget.aesthetics?.getColorMapping(uiElement);

    if (mapping == null) {
      // Fallback to current manual approach
      return _getDefaultWidgetColors();
    }

    // Start with defaults and override with mapped colors
    final resolved = _getDefaultWidgetColors();

    // Resolve slot references to actual colors
    mapping.forEach((property, slot) {
      final hexColor = widget.aesthetics!.palette.getColor(slot);
      if (hexColor != null) {
        resolved[property] = hexColor.toColor();
      }
    });

    return resolved;
  }

  /// Default widget colors when no color mapping exists
  Map<String, Color> _getDefaultWidgetColors() {
    return {
      'activeColor': _accentColor,
      'inactiveColor': _accent2 ?? _tone2 ?? Colors.grey.shade300,
      'thumbColor': _accentColor,
      'activeTrackColor': _accentColor,
      'activeThumbColor': Colors.white,
      'inactiveTrackColor': _tone2 ?? Colors.grey.shade300,
      'inactiveThumbColor': Colors.white,
      'cursorColor': _accentColor,
      'focusedBorderColor': _accentColor,
      'borderColor': _tone2 ?? Colors.grey.shade300,
      'fillColor': Colors.white,
      'errorBorderColor': context.colors.errorColor,
      'buttonColor': _accentColor,
      'iconColor': Colors.white,
      'valueColor': QuanityaPalette.primary.textPrimary,
      'dropdownColor': Colors.white,
      'dropdownIconColor': _tone1 ?? QuanityaPalette.primary.textPrimary,
      'primaryColor': _accentColor,
      'backgroundColor': Colors.white,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: ZenPaperBackground(
        baseColor: QuanityaPalette.primary.backgroundPrimary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scrollable content: header + fields
            Expanded(
              child: ListView(
                padding: AppPadding.page,
                children: [
                  // Header: Icon + Title centered
                  _buildHeader(),

                  VSpace.x3,

                  // Fields
                  ...widget.template.fields.map(
                    (field) => Padding(
                      padding: AppPadding.verticalSingle,
                      child: _buildField(field),
                    ),
                  ),
                ],
              ),
            ),

            // Actions (fixed at bottom)
            if (widget.actions.isNotEmpty) _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        VSpace.x2,

        // Icon/Emoji centered
        _buildIconOrEmoji(),

        VSpace.x2,

        // Template name centered
        Text(
          widget.template.name,
          textAlign: TextAlign.center,
          style: _titleStyle.copyWith(
            fontSize: AppSizes.fontLarge,
            color: QuanityaPalette.primary.textPrimary,
          ),
        ),

        // Theme name if available
        if (widget.aesthetics?.themeName != null) ...[
          VSpace.x05,
          Text(
            widget.aesthetics!.themeName!,
            textAlign: TextAlign.center,
            style: _bodyStyle.copyWith(
              fontSize: AppSizes.fontSmall,
              color: _secondaryColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIconOrEmoji() {
    final aesthetics = widget.aesthetics;

    // Emoji first
    if (aesthetics?.emoji != null && aesthetics!.emoji!.isNotEmpty) {
      return Container(
        width: AppSizes.iconXLarge,
        height: AppSizes.iconXLarge,
        decoration: BoxDecoration(
          color: _accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        alignment: Alignment.center,
        child: Text(
          aesthetics.emoji!,
          style: TextStyle(fontSize: AppSizes.iconLarge),
        ),
      );
    }

    // Icon
    if (aesthetics?.icon != null && aesthetics!.icon!.isNotEmpty) {
      final iconData = IconResolver.resolve(aesthetics.icon!);
      if (iconData != null) {
        return Container(
          width: AppSizes.iconXLarge,
          height: AppSizes.iconXLarge,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          alignment: Alignment.center,
          child: Icon(iconData, size: AppSizes.iconLarge, color: _accentColor),
        );
      }
    }

    // Default
    return Container(
      width: AppSizes.iconXLarge,
      height: AppSizes.iconXLarge,
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.assignment_outlined,
        size: AppSizes.iconLarge,
        color: _accentColor,
      ),
    );
  }

  Widget _buildField(TemplateField field) {
    final widgetColors = _resolveWidgetColors(
      field.uiElement?.name ?? 'default',
    );

    final fieldContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: _bodyStyle.copyWith(
            fontSize: AppSizes.fontStandard,
            color: QuanityaPalette.primary.textPrimary,
          ),
        ),
        VSpace.x1,
        DynamicFieldBuilder.buildField(
          field: field,
          value: _previewValues[field.id],
          onChanged: (value) => _updatePreviewValue(field.id, value),
          palette: _palette,
          widgetColors: widgetColors,
          textStyle: _bodyStyle.copyWith(
            color: QuanityaPalette.primary.textPrimary,
          ),
        ),
      ],
    );

    // Wrap with styled container if containerStyle is set
    final containerStyle = widget.aesthetics?.containerStyle;
    if (containerStyle != null &&
        containerStyle != TemplateContainerStyle.zen) {
      return StyledFieldContainer(
        preset: containerStyle,
        accentColor: _accentColor,
        child: fieldContent,
      );
    }

    return fieldContent;
  }

  Widget _buildActions() {
    return Padding(
      padding: AppPadding.page,
      child: Column(
        children: [
          Divider(height: 1, color: _tone2 ?? Theme.of(context).dividerColor),
          VSpace.x2,
          Row(
            children: widget.actions.map((action) {
              final isLast = action == widget.actions.last;
              return Expanded(
                flex: action.isPrimary ? 2 : 1,
                child: Padding(
                  padding: isLast
                      ? EdgeInsets.zero
                      : AppPadding.horizontalSingle,
                  child: action.isPrimary
                      ? FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            textStyle: _bodyStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: action.onPressed,
                          icon: Icon(action.icon),
                          label: Text(action.label),
                        )
                      : OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accentColor,
                            side: BorderSide(color: _accentColor),
                            textStyle: _bodyStyle,
                          ),
                          onPressed: action.onPressed,
                          icon: Icon(action.icon),
                          label: Text(action.label),
                        ),
                ),
              );
            }).toList(),
          ),
          VSpace.x1,
        ],
      ),
    );
  }

  // Font helpers
  TextStyle _getGoogleFontStyle(String? fontName) {
    if (fontName == null || fontName.isEmpty || fontName == 'system') {
      return const TextStyle();
    }
    if (!AllowedFont.isAllowed(fontName)) return const TextStyle();

    // Use FontPreloaderService for proper bundled font handling
    final fontService = GetIt.I<FontPreloaderService>();
    return fontService.getTextStyle(fontName);
  }

  TextStyle get _titleStyle {
    final fontName = widget.aesthetics?.fontConfig.titleFontFamily;
    final weight = widget.aesthetics?.fontConfig.titleWeight ?? 600;
    return _getGoogleFontStyle(fontName).copyWith(
      fontWeight: FontWeight.values.firstWhere(
        (w) => w.value == weight,
        orElse: () => FontWeight.w600,
      ),
    );
  }

  TextStyle get _bodyStyle {
    final fontName = widget.aesthetics?.fontConfig.bodyFontFamily;
    final weight = widget.aesthetics?.fontConfig.bodyWeight ?? 400;
    return _getGoogleFontStyle(fontName).copyWith(
      fontWeight: FontWeight.values.firstWhere(
        (w) => w.value == weight,
        orElse: () => FontWeight.w400,
      ),
    );
  }

}

/// Action configuration for template preview
class TemplatePreviewAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const TemplatePreviewAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  const TemplatePreviewAction.primary({
    required this.label,
    required this.icon,
    required this.onPressed,
  }) : isPrimary = true;

  const TemplatePreviewAction.secondary({
    required this.label,
    required this.icon,
    required this.onPressed,
  }) : isPrimary = false;
}
