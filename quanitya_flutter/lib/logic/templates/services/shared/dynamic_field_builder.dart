import 'package:flutter/material.dart';
import '../../../../infrastructure/location/location_service.dart';

import '../../enums/field_enum.dart';
import '../../enums/ui_element_enum.dart';
import '../../models/shared/field_validator.dart';
import '../../models/shared/template_field.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_date_picker.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_dropdown.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_slider.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_stepper.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_text_field.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_toggle.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_multi_chip_group.dart';

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
  /// [widgetColors] - Optional pre-resolved widget colors
  /// [textStyle] - Optional text style for labels (uses aesthetic fonts)
  static Widget buildField({
    required TemplateField field,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
    Map<String, Color>? widgetColors,
    TextStyle? textStyle,
  }) {
    // Infer uiElement from field type when not explicitly set
    if (field.uiElement == null) {
      final inferred = _inferUiElement(field.type);
      if (inferred != null) {
        field = field.copyWith(uiElement: inferred);
      }
    }

    // Handle list fields
    if (field.isList) {
      return _buildListField(
        field: field,
        values: (value as List<dynamic>?) ?? [],
        onChanged: onChanged,
        widgetColors: widgetColors,
        textStyle: textStyle,
      );
    }

    // Handle multi-select fields
    if (field.type == FieldEnum.multiEnum) {
      return _buildMultiChipField(
        field: field,
        values: (value as List<dynamic>?)?.cast<String>() ?? <String>[],
        onChanged: onChanged,
        widgetColors: widgetColors,
      );
    }

    // Handle group fields
    if (field.type == FieldEnum.group) {
      return _buildGroupField(
        field: field,
        value: (value as Map<String, dynamic>?) ?? {},
        onChanged: onChanged,
        widgetColors: widgetColors,
        textStyle: textStyle,
      );
    }

    // Single value field
    return _buildSingleField(
      field: field,
      value: value,
      onChanged: onChanged,
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


  /// Infers a default UI element from the field's data type.
  static UiElementEnum? _inferUiElement(FieldEnum type) {
    return switch (type) {
      FieldEnum.text => UiElementEnum.textField,
      FieldEnum.integer => UiElementEnum.stepper,
      FieldEnum.float => UiElementEnum.slider,
      FieldEnum.boolean => UiElementEnum.toggleSwitch,
      FieldEnum.datetime => UiElementEnum.datetimePicker,
      FieldEnum.enumerated => UiElementEnum.dropdown,
      FieldEnum.location => UiElementEnum.locationPicker,
      FieldEnum.dimension => UiElementEnum.stepper,
      FieldEnum.reference => null,
      FieldEnum.group => null,
      FieldEnum.multiEnum => UiElementEnum.chips,
    };
  }

  /// Builds a list field with add/remove controls and bounds enforcement
  static Widget _buildListField({
    required TemplateField field,
    required List<dynamic> values,
    required ValueChanged<dynamic> onChanged,
    Map<String, Color>? widgetColors,
    TextStyle? textStyle,
  }) {
    final bounds = _getListBounds(field);
    final maxItems = bounds.maxItems;
    final minItems = bounds.minItems;
    final canAdd = maxItems == null || values.length < maxItems;
    final canRemove = minItems == null || values.length > minItems;

    // Use custom accent color from widgetColors, fallback to palette
    final accentColor = widgetColors?['activeColor']
        ?? QuanityaPalette.primary.interactableColor;
    final secondaryTextColor = widgetColors?['borderColor']
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
                  child: field.type == FieldEnum.group
                      ? _buildGroupField(
                          field: field,
                          value: (values[i] as Map<String, dynamic>?) ?? {},
                          onChanged: (newValue) {
                            final updated = List<dynamic>.from(values);
                            updated[i] = newValue;
                            onChanged(updated);
                          },
                          widgetColors: widgetColors,
                          textStyle: textStyle,
                        )
                      : _buildSingleField(
                          field: field,
                          value: values[i],
                          onChanged: (newValue) {
                            final updated = List<dynamic>.from(values);
                            updated[i] = newValue;
                            onChanged(updated);
                          },
                          widgetColors: widgetColors,
                          textStyle: textStyle,
                        ),
                ),
                HSpace.x1,
                // Remove button - disabled if at minItems
                Builder(
                  builder: (context) => QuanityaIconButton(
                    icon: Icons.remove_circle_outline,
                    onPressed: canRemove
                        ? () {
                            final updated = List<dynamic>.from(values)
                              ..removeAt(i);
                            onChanged(updated);
                          }
                        : null,
                    isDestructive: canRemove,
                    tooltip: canRemove
                        ? context.l10n.fieldBuilderTooltipRemove
                        : context.l10n.fieldBuilderTooltipMinItems,
                  ),
                ),
              ],
            ),
          ),

        VSpace.x1,

        // Add button - uses custom accent color
        if (canAdd)
          Builder(
            builder: (context) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: accentColor),
                HSpace.x05,
                QuanityaTextButton(
                  text: context.l10n.fieldBuilderAddItem(field.label),
                  onPressed: () {
                    final updated = List<dynamic>.from(values)
                      ..add(_getDefaultValue(field));
                    onChanged(updated);
                  },
                  style: baseTextStyle.copyWith(color: accentColor),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: AppPadding.verticalSingle,
            child: Builder(
              builder: (context) => Text(
                context.l10n.fieldBuilderMaxItemsReached(maxItems!),
                style: smallTextStyle.copyWith(color: secondaryTextColor),
              ),
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
      FieldEnum.group => _getGroupDefault(field),
      FieldEnum.multiEnum => <String>[],
    };
  }

  /// Builds a default value map for a group field from its sub-fields.
  static Map<String, dynamic> _getGroupDefault(TemplateField field) {
    final subFields = field.subFields;
    if (subFields == null || subFields.isEmpty) return {};
    final map = <String, dynamic>{};
    for (final subField in subFields) {
      if (subField.isDeleted) continue;
      map[subField.id] = subField.isList
          ? <dynamic>[]
          : _getDefaultValue(subField);
    }
    return map;
  }


  /// Builds a multi-select chip field for multiEnum type.
  static Widget _buildMultiChipField({
    required TemplateField field,
    required List<String> values,
    required ValueChanged<dynamic> onChanged,
    Map<String, Color>? widgetColors,
  }) {
    final options = field.options ?? [];
    if (options.isEmpty) {
      return Builder(
        builder: (context) =>
            Text(context.l10n.fieldBuilderNoOptions),
      );
    }

    final selectedColor = widgetColors?['selectedColor']
        ?? QuanityaPalette.primary.textPrimary;
    final unselectedColor = widgetColors?['unselectedColor']
        ?? QuanityaPalette.primary.interactableColor;

    return QuanityaMultiChipGroup<String>(
      values: values,
      options: options,
      labelBuilder: (opt) => opt,
      selectedColor: selectedColor,
      unselectedColor: unselectedColor,
      onChanged: (updated) => onChanged(updated),
    );
  }

  /// Builds a group field — renders sub-fields vertically in a squircle border.
  static Widget _buildGroupField({
    required TemplateField field,
    required Map<String, dynamic> value,
    required ValueChanged<dynamic> onChanged,
    Map<String, Color>? widgetColors,
    TextStyle? textStyle,
  }) {
    final subFields = field.subFields;
    if (subFields == null || subFields.isEmpty) {
      return const SizedBox.shrink();
    }

    final borderColor = widgetColors?['borderColor']
        ?? QuanityaPalette.primary.textSecondary;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: AppSizes.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      padding: AppPadding.allSingle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _buildSubFieldWidgets(
          subFields: subFields,
          value: value,
          onChanged: onChanged,
          widgetColors: widgetColors,
          textStyle: textStyle,
          labelColor: borderColor,
        ),
      ),
    );
  }

  /// Builds the list of sub-field widgets for a group, filtering deleted fields.
  static List<Widget> _buildSubFieldWidgets({
    required List<TemplateField> subFields,
    required Map<String, dynamic> value,
    required ValueChanged<dynamic> onChanged,
    Map<String, Color>? widgetColors,
    TextStyle? textStyle,
    required Color labelColor,
  }) {
    final activeSubFields = subFields.where((f) => !f.isDeleted).toList();
    final widgets = <Widget>[];

    for (int i = 0; i < activeSubFields.length; i++) {
      final subField = activeSubFields[i];
      widgets.add(
        Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subField.label,
                style: context.text.bodySmall?.copyWith(
                  color: labelColor,
                ),
              ),
              VSpace.x05,
              buildField(
                field: subField,
                value: value[subField.id],
                onChanged: (newSubValue) {
                  final updated = Map<String, dynamic>.from(value);
                  updated[subField.id] = newSubValue;
                  onChanged(updated);
                },
                widgetColors: widgetColors,
                textStyle: textStyle,
              ),
            ],
          ),
        ),
      );
      if (i < activeSubFields.length - 1) {
        widgets.add(VSpace.x1);
      }
    }

    return widgets;
  }

  /// Builds a single-value field widget based on uiElement
  static Widget _buildSingleField({
    required TemplateField field,
    required dynamic value,
    required ValueChanged<dynamic> onChanged,
    Map<String, Color>? widgetColors,
    TextStyle? textStyle,
  }) {
    final uiElement = field.uiElement;
    if (uiElement == null) {
      // Defensive: should be caught by assert in buildField
      return Builder(
        builder: (context) => Text(context.l10n.fieldBuilderNoUiElement),
      );
    }
    return switch (uiElement) {
      UiElementEnum.slider =>
        _buildSlider(field, value, onChanged, widgetColors),
      UiElementEnum.stepper =>
        _buildStepper(field, value, onChanged, widgetColors),
      UiElementEnum.textField =>
        _buildTextField(field, value, onChanged, widgetColors, textStyle),
      UiElementEnum.textArea =>
        _buildTextArea(field, value, onChanged, widgetColors, textStyle),
      UiElementEnum.toggleSwitch =>
        _buildToggle(field, value, onChanged, widgetColors),
      UiElementEnum.checkbox =>
        _buildToggle(field, value, onChanged, widgetColors),
      UiElementEnum.dropdown =>
        _buildDropdown(field, value, onChanged, widgetColors, textStyle),
      UiElementEnum.radio =>
        _buildDropdown(field, value, onChanged, widgetColors, textStyle),
      UiElementEnum.chips =>
        _buildDropdown(field, value, onChanged, widgetColors, textStyle),
      UiElementEnum.datePicker =>
        _buildDatePicker(field, value, onChanged, widgetColors, textStyle),
      UiElementEnum.timePicker =>
        _buildDatePicker(field, value, onChanged, widgetColors, textStyle),
      UiElementEnum.datetimePicker =>
        _buildDatePicker(field, value, onChanged, widgetColors, textStyle),
      UiElementEnum.searchField =>
        _buildTextField(field, value, onChanged, widgetColors, textStyle),
      UiElementEnum.locationPicker =>
        _buildLocationPicker(field, value, onChanged, widgetColors, textStyle),
      UiElementEnum.timer =>
        _buildTimer(field, value, onChanged, widgetColors, textStyle),
    };
  }

  static Widget _buildSlider(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    Map<String, Color>? colors,
  ) {
    final numValue = (value as num?)?.toDouble() ?? 0.0;
    final constraints = _getNumericConstraints(field);
    final isInteger = field.type == FieldEnum.integer;

    return QuanityaSlider(
      value: numValue,
      min: constraints.min,
      max: constraints.max,
      semanticLabel: field.label,
      onChanged: (v) => onChanged(isInteger ? v.toInt() : v),
      activeColor:
          colors?['activeColor'] ?? QuanityaPalette.primary.interactableColor,
      inactiveColor:
          colors?['inactiveColor'] ?? QuanityaPalette.primary.textSecondary,
      thumbColor:
          colors?['thumbColor'] ?? QuanityaPalette.primary.interactableColor,
    );
  }

  static Widget _buildStepper(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
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
          colors?['buttonColor'] ?? QuanityaPalette.primary.interactableColor,
      iconColor: colors?['iconColor'] ?? QuanityaPalette.primary.backgroundPrimary,
      valueColor:
          colors?['valueColor'] ?? QuanityaPalette.primary.textPrimary,
    );
  }


  static Widget _buildTextField(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    final controller = TextEditingController(text: value?.toString() ?? '');
    return Builder(
      builder: (context) => QuanityaTextField(
        controller: controller,
        hintText: context.l10n.fieldBuilderEnterHint(field.label.toLowerCase()),
        semanticLabel: field.label,
        onChanged: onChanged,
        style: textStyle,
        textColor: textStyle?.color,
        hintColor: colors?['borderColor']?.withValues(alpha: 0.6),
        cursorColor:
            colors?['cursorColor'] ?? QuanityaPalette.primary.interactableColor,
        fillColor: colors?['fillColor'] ?? QuanityaPalette.primary.backgroundPrimary,
        borderColor:
            colors?['borderColor'] ?? QuanityaPalette.primary.textSecondary,
        focusedBorderColor:
            colors?['focusedBorderColor'] ?? QuanityaPalette.primary.interactableColor,
        errorBorderColor: colors?['errorBorderColor'] ?? QuanityaPalette.primary.destructiveColor,
      ),
    );
  }

  static Widget _buildTextArea(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    final controller = TextEditingController(text: value?.toString() ?? '');
    return Builder(
      builder: (context) => QuanityaTextField(
        controller: controller,
        hintText: context.l10n.fieldBuilderEnterHint(field.label.toLowerCase()),
        semanticLabel: field.label,
        onChanged: onChanged,
        maxLines: 4,
        style: textStyle,
        textColor: textStyle?.color,
        hintColor: colors?['borderColor']?.withValues(alpha: 0.6),
        cursorColor:
            colors?['cursorColor'] ?? QuanityaPalette.primary.interactableColor,
        fillColor: colors?['fillColor'] ?? QuanityaPalette.primary.backgroundPrimary,
        borderColor:
            colors?['borderColor'] ?? QuanityaPalette.primary.textSecondary,
        focusedBorderColor:
            colors?['focusedBorderColor'] ?? QuanityaPalette.primary.interactableColor,
        errorBorderColor: colors?['errorBorderColor'] ?? QuanityaPalette.primary.destructiveColor,
      ),
    );
  }

  static Widget _buildToggle(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    Map<String, Color>? colors,
  ) {
    final boolValue = value as bool? ?? false;

    return QuanityaToggle(
      value: boolValue,
      onChanged: onChanged,
      semanticLabel: field.label,
      activeThumbColor: colors?['activeThumbColor'] ?? QuanityaPalette.primary.backgroundPrimary,
      activeTrackColor:
          colors?['activeTrackColor'] ?? QuanityaPalette.primary.interactableColor,
      inactiveThumbColor: colors?['inactiveThumbColor'] ?? QuanityaPalette.primary.backgroundPrimary,
      inactiveTrackColor:
          colors?['inactiveTrackColor'] ?? QuanityaPalette.primary.textSecondary,
    );
  }

  static Widget _buildDropdown(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    final options = field.options ?? [];
    if (options.isEmpty) {
      return Builder(
        builder: (context) =>
            Text(context.l10n.fieldBuilderNoOptions, style: textStyle),
      );
    }

    return Builder(
      builder: (context) => QuanityaDropdown<String>(
        value: value as String?,
        items: options
            .map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt, style: textStyle),
                ))
            .toList(),
        onChanged: onChanged,
        hintText: context.l10n.fieldBuilderSelectHint(field.label.toLowerCase()),
        style: textStyle,
        dropdownColor: colors?['dropdownColor'] ?? QuanityaPalette.primary.backgroundPrimary,
        fillColor: colors?['fillColor'] ?? QuanityaPalette.primary.backgroundPrimary,
        borderColor:
            colors?['borderColor'] ?? QuanityaPalette.primary.textSecondary,
        iconColor:
            colors?['iconColor'] ?? QuanityaPalette.primary.textSecondary,
      ),
    );
  }

  static Widget _buildDatePicker(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    return Builder(
      builder: (context) => QuanityaDatePicker(
        value: value as DateTime?,
        onChanged: onChanged,
        hintText: context.l10n.fieldBuilderSelectHint(field.label.toLowerCase()),
        textStyle: textStyle,
        primaryColor:
            colors?['primaryColor'] ?? QuanityaPalette.primary.interactableColor,
        backgroundColor: colors?['backgroundColor'] ?? QuanityaPalette.primary.backgroundPrimary,
        borderColor:
            colors?['borderColor'] ?? QuanityaPalette.primary.textSecondary,
        fillColor: colors?['fillColor'] ?? QuanityaPalette.primary.backgroundPrimary,
      ),
    );
  }

  static Widget _buildLocationPicker(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    final locationMap = value is Map<String, dynamic> ? value : null;
    final hasLocation = locationMap != null &&
        locationMap.containsKey('latitude') &&
        locationMap.containsKey('longitude');

    final accentColor = colors?['activeColor'] ??
        QuanityaPalette.primary.interactableColor;
    final secondaryColor = colors?['borderColor'] ??
        QuanityaPalette.primary.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLocation)
          Padding(
            padding: AppPadding.verticalSingle,
            child: Text(
              '${locationMap['latitude'].toStringAsFixed(5)}, '
              '${locationMap['longitude'].toStringAsFixed(5)}',
              style: textStyle?.copyWith(color: secondaryColor),
            ),
          ),
        Builder(
          builder: (context) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasLocation ? Icons.my_location : Icons.location_on_outlined,
                color: accentColor,
              ),
              HSpace.x05,
              QuanityaTextButton(
                text: hasLocation
                    ? context.l10n.fieldBuilderUpdateLocation
                    : context.l10n.fieldBuilderCaptureLocation,
                onPressed: () async {
                  try {
                    final location = await LocationService.captureCurrentPosition();
                    onChanged(location);
                  } catch (e) {
                    // Permission denied or location unavailable — don't crash
                    debugPrint('Location capture failed: $e');
                  }
                },
                style: textStyle?.copyWith(color: accentColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildTimer(
    TemplateField field,
    dynamic value,
    ValueChanged<dynamic> onChanged,
    Map<String, Color>? colors,
    TextStyle? textStyle,
  ) {
    final elapsedSeconds = (value as num?)?.toInt() ?? 0;
    final isInteger = field.type == FieldEnum.integer;

    return _TimerWidget(
      elapsedSeconds: elapsedSeconds,
      onChanged: (seconds) => onChanged(isInteger ? seconds : seconds.toDouble()),
      accentColor: colors?['activeColor'] ??
          QuanityaPalette.primary.interactableColor,
      secondaryColor: colors?['borderColor'] ??
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
                fontSize: AppSizes.fontLarge,
                fontFeatures: [const FontFeature.tabularFigures()],
              ) ??
              TextStyle(
                fontSize: AppSizes.fontLarge,
                color: widget.secondaryColor,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
        ),
        HSpace.x1,
        QuanityaIconButton(
          icon: _running ? Icons.stop_circle_outlined : Icons.play_circle_outline,
          onPressed: _toggle,
          iconSize: AppSizes.iconLarge,
          color: widget.accentColor,
          tooltip: _running ? context.l10n.tooltipStop : context.l10n.tooltipStart,
        ),
        if (!_running && display > 0)
          QuanityaIconButton(
            icon: Icons.replay,
            onPressed: _reset,
            iconSize: AppSizes.iconMedium,
            color: widget.secondaryColor,
            tooltip: context.l10n.tooltipReset,
          ),
      ],
    );
  }
}
