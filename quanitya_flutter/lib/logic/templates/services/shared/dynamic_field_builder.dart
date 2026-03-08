import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import '../../../../infrastructure/location/location_service.dart';

import '../../enums/field_enum.dart';
import '../../enums/ui_element_enum.dart';
import '../../models/shared/field_validator.dart';
import '../../models/shared/template_field.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_date_picker.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_dropdown.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_slider.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_stepper.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_text_field.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_toggle.dart';

/// Builds appropriate input widgets for dynamic template fields.
///
/// Uses field.uiElement to determine which widget to render.
/// Supports both single-value and list fields (isList: true).
class DynamicFieldBuilder {
  DynamicFieldBuilder._();

  /// Builds a widget based on field.uiElement.
  ///
  /// [field] - The template field definition (must have uiElement set)
  /// [value] - Current value (type depends on field.type, List if isList)
  /// [onChanged] - Callback when value changes
  /// [palette] - Color palette for styling
  /// [widgetColors] - Optional pre-resolved widget colors
  /// [textStyle] - Optional text style for labels (uses aesthetic fonts)
  static Widget buildField({
    required TemplateField field,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
    required IColorPalette palette,
    Map<String, Color>? widgetColors,
    TextStyle? textStyle,
  }) {
    // Handle legacy fields without uiElement (graceful fallback)
    if (field.uiElement == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.getColor('neutral2')?.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: palette.getColor('neutral1')?.withValues(alpha: 0.2) ?? Colors.grey,
          ),
        ),
        child: Text(
          'No UI element selected: ${field.label}\nValue: ${value?.toString() ?? 'No value'}',
          style: textStyle?.copyWith(
            color: palette.getColor('neutral1')?.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Handle list fields
    if (field.isList) {
      return _buildListField(
        field: field,
        values: (value as List<dynamic>?) ?? [],
        onChanged: onChanged,
        palette: palette,
        widgetColors: widgetColors,
        textStyle: textStyle,
      );
    }

    // Single value field
    return _buildSingleField(
      field: field,
      value: value,
      onChanged: onChanged,
      palette: palette,
      widgetColors: widgetColors,
      textStyle: textStyle,
    );
  }

  /// Extracts list bounds from field validators
  static ({int? minItems, int? maxItems}) _getListBounds(TemplateField field) {
    for (final validator in field.validators) {
      if (validator.validatorType == ValidatorType.list) {
        return (
          minItems: validator.validatorData['minItems'] as int?,
          maxItems: validator.validatorData['maxItems'] as int?,
        );
      }
    }
    return (minItems: null, maxItems: null);
  }


  /// Builds a list field with add/remove controls and bounds enforcement
  static Widget _buildListField({
    required TemplateField field,
    required List<dynamic> values,
    required ValueChanged<dynamic> onChanged,
    required IColorPalette palette,
    Map<String, Color>? widgetColors,
    TextStyle? textStyle,
  }) {
    final bounds = _getListBounds(field);
    final maxItems = bounds.maxItems;
    final minItems = bounds.minItems;
    final canAdd = maxItems == null || values.length < maxItems;
    final canRemove = minItems == null || values.length > minItems;
    
    // Use custom accent color from widgetColors, fallback to palette or default
    final accentColor = widgetColors?['activeColor'] 
        ?? palette.getColor('color1') 
        ?? QuanityaPalette.primary.interactableColor;
    final secondaryTextColor = widgetColors?['borderColor']
        ?? palette.getColor('neutral1')
        ?? QuanityaPalette.primary.textSecondary;

    // Base text style - use provided or create minimal fallback
    final baseTextStyle = textStyle ?? const TextStyle();
    final smallTextStyle = baseTextStyle.copyWith(
      fontSize: baseTextStyle.fontSize != null 
          ? baseTextStyle.fontSize! * 0.85 
          : 12,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with count indicator (if bounded)
        if (maxItems != null)
          Padding(
            padding: AppPadding.verticalSingle,
            child: Text(
              '${field.label} (${values.length}/$maxItems)',
              style: smallTextStyle.copyWith(color: secondaryTextColor),
            ),
          ),

        // Render each value with remove button
        for (int i = 0; i < values.length; i++)
          Padding(
            padding: AppPadding.verticalSingle,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildSingleField(
                    field: field,
                    value: values[i],
                    onChanged: (newValue) {
                      final updated = List<dynamic>.from(values);
                      updated[i] = newValue;
                      onChanged(updated);
                    },
                    palette: palette,
                    widgetColors: widgetColors,
                    textStyle: textStyle,
                  ),
                ),
                HSpace.x1,
                // Remove button - disabled if at minItems
                QuanityaIconButton(
                  icon: Icons.remove_circle_outline,
                  onPressed: canRemove
                      ? () {
                          final updated = List<dynamic>.from(values)
                            ..removeAt(i);
                          onChanged(updated);
                        }
                      : null,
                  isDestructive: canRemove,
                  tooltip: canRemove ? 'Remove' : 'Minimum items reached',
                ),
              ],
            ),
          ),

        VSpace.x1,

        // Add button - uses custom accent color
        if (canAdd)
          TextButton.icon(
            icon: Icon(Icons.add, color: accentColor),
            label: Text(
              'Add ${field.label}',
              style: baseTextStyle.copyWith(color: accentColor),
            ),
            onPressed: () {
              final updated = List<dynamic>.from(values)
                ..add(_getDefaultValue(field));
              onChanged(updated);
            },
          )
        else
          Padding(
            padding: AppPadding.verticalSingle,
            child: Text(
              'Maximum $maxItems items reached',
              style: smallTextStyle.copyWith(color: secondaryTextColor),
            ),
          ),
      ],
    );
  }

  /// Gets the type-safe default value for adding new list items.
  /// 
  /// For list items, we use the type default (not field.defaultValue)
  /// since the user is adding a new item to the list.
  static dynamic _getDefaultValue(TemplateField field) {
    return switch (field.type) {
      FieldEnum.integer => 0,
      FieldEnum.float => 0.0,
      FieldEnum.boolean => false,
      FieldEnum.text => '',
      FieldEnum.datetime => null,
      FieldEnum.enumerated => field.options?.firstOrNull,
      FieldEnum.dimension => 0.0,
      FieldEnum.reference => null,
      FieldEnum.location => null,
    };
  }


  /// Builds a single-value field widget based on uiElement
  static Widget _buildSingleField({
    required TemplateField field,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
    required IColorPalette palette,
    Map<String, Color>? widgetColors,
    TextStyle? textStyle,
  }) {
    final uiElement = field.uiElement;
    if (uiElement == null) {
      // Defensive: should be caught by assert in buildField
      return const Text('No UI element defined');
    }
    return switch (uiElement) {
      UiElementEnum.slider =>
        _buildSlider(field, value, onChanged, palette, widgetColors),
      UiElementEnum.stepper =>
        _buildStepper(field, value, onChanged, palette, widgetColors),
      UiElementEnum.textField =>
        _buildTextField(field, value, onChanged, palette, widgetColors, textStyle),
      UiElementEnum.textArea =>
        _buildTextArea(field, value, onChanged, palette, widgetColors, textStyle),
      UiElementEnum.toggleSwitch =>
        _buildToggle(field, value, onChanged, palette, widgetColors),
      UiElementEnum.checkbox =>
        _buildToggle(field, value, onChanged, palette, widgetColors),
      UiElementEnum.dropdown =>
        _buildDropdown(field, value, onChanged, palette, widgetColors, textStyle),
      UiElementEnum.radio =>
        _buildDropdown(field, value, onChanged, palette, widgetColors, textStyle),
      UiElementEnum.chips =>
        _buildDropdown(field, value, onChanged, palette, widgetColors, textStyle),
      UiElementEnum.datePicker =>
        _buildDatePicker(field, value, onChanged, palette, widgetColors, textStyle),
      UiElementEnum.timePicker =>
        _buildDatePicker(field, value, onChanged, palette, widgetColors, textStyle),
      UiElementEnum.datetimePicker =>
        _buildDatePicker(field, value, onChanged, palette, widgetColors, textStyle),
      UiElementEnum.searchField =>
        _buildTextField(field, value, onChanged, palette, widgetColors, textStyle),
      UiElementEnum.locationPicker =>
        _buildLocationPicker(field, value, onChanged, palette, widgetColors, textStyle),
      UiElementEnum.timer =>
        _buildTimer(field, value, onChanged, palette, widgetColors, textStyle),
    };
  }

  static Widget _buildSlider(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    IColorPalette palette,
    Map<String, Color>? colors,
  ) {
    final numValue = (value as num?)?.toDouble() ?? 0.0;
    final constraints = _getNumericConstraints(field);
    final isInteger = field.type == FieldEnum.integer;

    return QuanityaSlider(
      value: numValue,
      min: constraints.min,
      max: constraints.max,
      onChanged: (v) => onChanged(isInteger ? v.toInt() : v),
      activeColor:
          colors?['activeColor'] ?? palette.getColor('color1') ?? Colors.blue,
      inactiveColor:
          colors?['inactiveColor'] ?? palette.getColor('neutral2') ?? Colors.grey,
      thumbColor:
          colors?['thumbColor'] ?? palette.getColor('color1') ?? Colors.blue,
    );
  }

  static Widget _buildStepper(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    IColorPalette palette,
    Map<String, Color>? colors,
  ) {
    final intValue = (value as num?)?.toInt() ?? 0;
    final constraints = _getNumericConstraints(field);

    return QuanityaStepper(
      value: intValue,
      min: constraints.min.toInt(),
      max: constraints.max.toInt(),
      onChanged: onChanged,
      buttonColor:
          colors?['buttonColor'] ?? palette.getColor('color1') ?? Colors.blue,
      iconColor: colors?['iconColor'] ?? Colors.white,
      valueColor:
          colors?['valueColor'] ?? palette.getColor('neutral1') ?? Colors.black,
    );
  }


  static Widget _buildTextField(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    IColorPalette palette,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    return QuanityaTextField(
      hintText: 'Enter ${field.label.toLowerCase()}',
      onChanged: onChanged,
      style: textStyle,
      textColor: textStyle?.color,
      hintColor: colors?['borderColor']?.withValues(alpha: 0.6) 
          ?? palette.getColor('neutral2')?.withValues(alpha: 0.6),
      cursorColor:
          colors?['cursorColor'] ?? palette.getColor('color1') ?? Colors.blue,
      fillColor: colors?['fillColor'] ?? Colors.white,
      borderColor:
          colors?['borderColor'] ?? palette.getColor('neutral2') ?? Colors.grey,
      focusedBorderColor:
          colors?['focusedBorderColor'] ?? palette.getColor('color1') ?? Colors.blue,
      errorBorderColor: colors?['errorBorderColor'] ?? Colors.red,
    );
  }

  static Widget _buildTextArea(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    IColorPalette palette,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    return QuanityaTextField(
      hintText: 'Enter ${field.label.toLowerCase()}',
      onChanged: onChanged,
      maxLines: 4,
      style: textStyle,
      textColor: textStyle?.color,
      hintColor: colors?['borderColor']?.withValues(alpha: 0.6) 
          ?? palette.getColor('neutral2')?.withValues(alpha: 0.6),
      cursorColor:
          colors?['cursorColor'] ?? palette.getColor('color1') ?? Colors.blue,
      fillColor: colors?['fillColor'] ?? Colors.white,
      borderColor:
          colors?['borderColor'] ?? palette.getColor('neutral2') ?? Colors.grey,
      focusedBorderColor:
          colors?['focusedBorderColor'] ?? palette.getColor('color1') ?? Colors.blue,
      errorBorderColor: colors?['errorBorderColor'] ?? Colors.red,
    );
  }

  static Widget _buildToggle(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    IColorPalette palette,
    Map<String, Color>? colors,
  ) {
    final boolValue = value as bool? ?? false;

    return QuanityaToggle(
      value: boolValue,
      onChanged: onChanged,
      activeThumbColor: colors?['activeThumbColor'] ?? Colors.white,
      activeTrackColor:
          colors?['activeTrackColor'] ?? palette.getColor('color1') ?? Colors.blue,
      inactiveThumbColor: colors?['inactiveThumbColor'] ?? Colors.white,
      inactiveTrackColor:
          colors?['inactiveTrackColor'] ?? palette.getColor('neutral2') ?? Colors.grey,
    );
  }

  static Widget _buildDropdown(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    IColorPalette palette,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    final options = field.options ?? [];
    if (options.isEmpty) {
      return Text('No options available', style: textStyle);
    }

    return QuanityaDropdown<String>(
      value: value as String?,
      items: options
          .map((opt) => DropdownMenuItem(
                value: opt,
                child: Text(opt, style: textStyle),
              ))
          .toList(),
      onChanged: onChanged,
      hintText: 'Select ${field.label.toLowerCase()}',
      style: textStyle,
      dropdownColor: colors?['dropdownColor'] ?? Colors.white,
      fillColor: colors?['fillColor'] ?? Colors.white,
      borderColor:
          colors?['borderColor'] ?? palette.getColor('neutral2') ?? Colors.grey,
      iconColor:
          colors?['iconColor'] ?? palette.getColor('neutral1') ?? Colors.grey,
    );
  }

  static Widget _buildDatePicker(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    IColorPalette palette,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    return QuanityaDatePicker(
      value: value as DateTime?,
      onChanged: onChanged,
      hintText: 'Select ${field.label.toLowerCase()}',
      textStyle: textStyle,
      primaryColor:
          colors?['primaryColor'] ?? palette.getColor('color1') ?? Colors.blue,
      backgroundColor: colors?['backgroundColor'] ?? Colors.white,
      borderColor:
          colors?['borderColor'] ?? palette.getColor('neutral2') ?? Colors.grey,
      fillColor: colors?['fillColor'] ?? Colors.white,
    );
  }

  static Widget _buildLocationPicker(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    IColorPalette palette,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    final locationMap = value is Map<String, dynamic> ? value : null;
    final hasLocation = locationMap != null &&
        locationMap.containsKey('latitude') &&
        locationMap.containsKey('longitude');

    final accentColor = colors?['activeColor'] ??
        palette.getColor('color1') ??
        QuanityaPalette.primary.interactableColor;
    final secondaryColor = colors?['borderColor'] ??
        palette.getColor('neutral1') ??
        QuanityaPalette.primary.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLocation)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${locationMap!['latitude'].toStringAsFixed(5)}, '
              '${locationMap['longitude'].toStringAsFixed(5)}',
              style: textStyle?.copyWith(color: secondaryColor) ??
                  TextStyle(color: secondaryColor, fontSize: 13),
            ),
          ),
        TextButton.icon(
          icon: Icon(
            hasLocation ? Icons.my_location : Icons.location_on_outlined,
            color: accentColor,
          ),
          label: Text(
            hasLocation ? 'Update Location' : 'Capture Location',
            style: textStyle?.copyWith(color: accentColor) ??
                TextStyle(color: accentColor),
          ),
          onPressed: () async {
            try {
              final location = await LocationService.captureCurrentPosition();
              onChanged(location);
            } catch (e) {
              // Permission denied or location unavailable — don't crash
              debugPrint('Location capture failed: $e');
            }
          },
        ),
      ],
    );
  }

  static Widget _buildTimer(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    IColorPalette palette,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    final elapsedSeconds = (value as num?)?.toInt() ?? 0;
    final isInteger = field.type == FieldEnum.integer;

    return _TimerWidget(
      elapsedSeconds: elapsedSeconds,
      onChanged: (seconds) => onChanged(isInteger ? seconds : seconds.toDouble()),
      accentColor: colors?['activeColor'] ??
          palette.getColor('color1') ??
          QuanityaPalette.primary.interactableColor,
      secondaryColor: colors?['borderColor'] ??
          palette.getColor('neutral1') ??
          QuanityaPalette.primary.textSecondary,
      textStyle: textStyle,
    );
  }

  /// Extract numeric constraints from field validators
  static ({double min, double max}) _getNumericConstraints(TemplateField field) {
    double min = 0;
    double max = 100;

    for (final validator in field.validators) {
      if (validator.validatorType == ValidatorType.numeric) {
        final data = validator.validatorData;
        if (data.containsKey('min')) {
          min = (data['min'] as num).toDouble();
        }
        if (data.containsKey('max')) {
          max = (data['max'] as num).toDouble();
        }
      }
    }

    return (min: min, max: max);
  }
}

/// Start/stop timer widget that records elapsed duration in seconds.
class _TimerWidget extends StatefulWidget {
  final int elapsedSeconds;
  final ValueChanged<int> onChanged;
  final Color accentColor;
  final Color secondaryColor;
  final TextStyle? textStyle;

  const _TimerWidget({
    required this.elapsedSeconds,
    required this.onChanged,
    required this.accentColor,
    required this.secondaryColor,
    this.textStyle,
  });

  @override
  State<_TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  late int _seconds;
  DateTime? _startedAt;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _seconds = widget.elapsedSeconds;
  }

  void _toggle() {
    setState(() {
      if (_running) {
        // Stop
        _running = false;
        if (_startedAt != null) {
          _seconds += DateTime.now().difference(_startedAt!).inSeconds;
          _startedAt = null;
        }
        widget.onChanged(_seconds);
      } else {
        // Start
        _running = true;
        _startedAt = DateTime.now();
        _tick();
      }
    });
  }

  void _tick() {
    if (!_running || !mounted) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (_running && mounted) {
        setState(() {});
        _tick();
      }
    });
  }

  void _reset() {
    setState(() {
      _running = false;
      _startedAt = null;
      _seconds = 0;
    });
    widget.onChanged(0);
  }

  int get _displaySeconds {
    if (_running && _startedAt != null) {
      return _seconds + DateTime.now().difference(_startedAt!).inSeconds;
    }
    return _seconds;
  }

  String _format(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Save final value if still running when widget disposes
    if (_running && _startedAt != null) {
      final finalSeconds = _seconds +
          DateTime.now().difference(_startedAt!).inSeconds;
      widget.onChanged(finalSeconds);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = _displaySeconds;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _format(display),
          style: widget.textStyle?.copyWith(
                fontSize: 28,
                fontFeatures: [const FontFeature.tabularFigures()],
              ) ??
              TextStyle(
                fontSize: 28,
                color: widget.secondaryColor,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(
            _running ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            size: 36,
            color: widget.accentColor,
          ),
          onPressed: _toggle,
          tooltip: _running ? 'Stop' : 'Start',
        ),
        if (!_running && display > 0)
          IconButton(
            icon: Icon(
              Icons.replay,
              size: 24,
              color: widget.secondaryColor,
            ),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
      ],
    );
  }
}
