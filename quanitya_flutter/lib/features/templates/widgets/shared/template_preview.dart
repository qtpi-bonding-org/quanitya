import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/bootstrap.dart' show getIt;

import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../../design_system/widgets/styled_field_container.dart';
import '../../../../support/extensions/color_extensions.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../logic/templates/enums/ai/allowed_font.dart';
import '../../../../logic/templates/enums/ai/template_preset.dart';
import '../../../../logic/templates/models/shared/template_aesthetics.dart';
import '../../../../logic/templates/models/shared/template_field.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import '../../../../logic/templates/services/shared/default_value_handler.dart';
import '../../../../logic/templates/services/shared/dynamic_field_builder.dart';
import '../../../../infrastructure/fonts/font_preloader_service.dart';
import '../../../../design_system/widgets/template_icon.dart';

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
  final Map<String, String?> fieldErrors;

  const TemplatePreview({
    super.key,
    required this.template,
    this.aesthetics,
    this.actions = const [],
    this.initialValues,
    this.onValuesChanged,
    this.fieldErrors = const {},
  });

  /// Factory for editor context
  factory TemplatePreview.editor({
    Key? key,
    required TrackerTemplateModel template,
    TemplateAestheticsModel? aesthetics,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required String editLabel,
    required String saveLabel,
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
          label: editLabel,
          icon: Icons.edit,
          onPressed: onEdit,
        ),
        TemplatePreviewAction.primary(
          label: saveLabel,
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
    required String saveLabel,
    String? discardLabel,
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
        if (onDiscard != null && discardLabel != null)
          TemplatePreviewAction.secondary(
            label: discardLabel,
            icon: Icons.close,
            onPressed: onDiscard,
          ),
        TemplatePreviewAction.primary(
          label: saveLabel,
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
    required String importLabel,
    String? cancelLabel,
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
        if (onCancel != null && cancelLabel != null)
          TemplatePreviewAction.secondary(
            label: cancelLabel,
            icon: Icons.close,
            onPressed: onCancel,
          ),
        TemplatePreviewAction.primary(
          label: importLabel,
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

  // Resolved accent colors from aesthetics
  Color? _accent1;
  Color? _accent2;
  Color? _tone1;
  Color? _tone2;

  @override
  void initState() {
    super.initState();
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

  void _initializeDefaultValues() {
    final handler = getIt<DefaultValueHandler>();
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
      'inactiveColor': _accent2 ?? _tone2 ?? QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3),
      'thumbColor': _accentColor,
      'activeTrackColor': _accentColor,
      'activeThumbColor': QuanityaPalette.primary.backgroundPrimary,
      'inactiveTrackColor': _tone2 ?? QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3),
      'inactiveThumbColor': QuanityaPalette.primary.backgroundPrimary,
      'cursorColor': _accentColor,
      'focusedBorderColor': _accentColor,
      'borderColor': _tone2 ?? QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3),
      'fillColor': QuanityaPalette.primary.backgroundPrimary,
      'errorBorderColor': context.colors.errorColor,
      'buttonColor': _accentColor,
      'iconColor': QuanityaPalette.primary.backgroundPrimary,
      'valueColor': QuanityaPalette.primary.textPrimary,
      'dropdownColor': QuanityaPalette.primary.backgroundPrimary,
      'dropdownIconColor': _tone1 ?? QuanityaPalette.primary.textPrimary,
      'primaryColor': _accentColor,
      'backgroundColor': QuanityaPalette.primary.backgroundPrimary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return Column(
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
    return TemplateIcon(
      iconString: widget.aesthetics?.icon,
      emoji: widget.aesthetics?.emoji,
      size: AppSizes.fontMassive,
      color: _accentColor,
      fallbackIcon: Icons.assignment_outlined,
    );
  }

  Widget _buildField(TemplateField field) {
    final widgetColors = _resolveWidgetColors(
      field.uiElement?.name ?? 'default',
    );

    final error = widget.fieldErrors[field.id];

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
          widgetColors: widgetColors,
          textStyle: _bodyStyle.copyWith(
            color: QuanityaPalette.primary.textPrimary,
          ),
        ),
        if (error != null) ...[
          VSpace.x05,
          Text(
            error,
            style: _bodyStyle.copyWith(
              fontSize: AppSizes.fontSmall,
              color: QuanityaPalette.primary.destructiveColor,
            ),
          ),
        ],
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
          VSpace.x2,
          Row(
            children: widget.actions.map((action) {
              return Expanded(
                child: QuanityaTextButton(
                  text: action.label,
                  onPressed: action.onPressed,
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
    final fontService = context.read<FontPreloaderService>();
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
