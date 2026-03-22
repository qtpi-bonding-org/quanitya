import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../logic/templates/enums/field_enum.dart';
import '../../../../logic/templates/enums/field_enum_extensions.dart';
import '../../../../logic/templates/enums/measurement_dimension.dart';
import '../../../../logic/templates/enums/measurement_unit.dart';
import '../../../../logic/templates/enums/ui_element_enum.dart';
import '../../../../logic/templates/models/shared/field_validator.dart';
import '../../../../logic/templates/models/shared/template_field.dart';
import '../../../../logic/templates/services/engine/symbolic_combination_generator.dart';
import '../../../../logic/templates/services/shared/default_value_handler.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya_text_field.dart';
import '../../../../design_system/widgets/quanitya/general/notebook_fold.dart';
import '../../../../design_system/widgets/quanitya/general/pen_circled_chip.dart';
import '../../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_toggle.dart';
import '../../../../support/extensions/context_extensions.dart';

/// Inline field editor for adding or editing template fields.
/// 
/// Expands in-place rather than showing a modal dialog.
/// Fits the manuscript aesthetic - editing feels like writing.
class InlineFieldEditor extends StatefulWidget {
  /// Field type (required for new fields)
  final FieldEnum fieldType;
  
  /// Existing field to edit (null for new fields)
  final TemplateField? existingField;
  
  /// Called when user saves the field
  final Function(TemplateField field) onSave;
  
  /// Called when user cancels editing
  final VoidCallback onCancel;

  const InlineFieldEditor({
    super.key,
    required this.fieldType,
    required this.onSave,
    required this.onCancel,
    this.existingField,
  });

  bool get isEditing => existingField != null;

  @override
  State<InlineFieldEditor> createState() => _InlineFieldEditorState();
}

class _InlineFieldEditorState extends State<InlineFieldEditor> {
  late final TextEditingController _labelController;
  late final TextEditingController _optionController;
  late final TextEditingController _defaultValueController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final DefaultValueHandler _defaultHandler;
  late final List<UiElementEnum> _validWidgets;
  late UiElementEnum _selectedWidget;
  late bool _isList;
  late List<String> _options;
  MeasurementUnit? _selectedUnit;
  late bool _isOptional;

  // Default value state (type varies by field)
  Object? _defaultValue;
  String? _defaultValueError;

  @override
  void initState() {
    super.initState();
    
    final generator = GetIt.I<SymbolicCombinationGenerator>();
    _defaultHandler = GetIt.I<DefaultValueHandler>();
    _validWidgets = generator.getValidUiElementsForField(widget.fieldType);
    
    if (widget.isEditing) {
      final field = widget.existingField!;
      _labelController = TextEditingController(text: field.label);
      _selectedWidget = field.uiElement ?? _validWidgets.first;
      _isList = field.isList;
      _options = List.from(field.options ?? []);
      _selectedUnit = field.unit;
      _defaultValue = field.defaultValue;
      _isOptional = field.validators.any(
        (v) => v.validatorType == ValidatorType.optional,
      );
      _defaultValueController = TextEditingController(
        text: _defaultValueToString(field.defaultValue),
      );

      // Initialize min/max from existing numeric/dimension validator
      final numericValidator = field.validators
          .where((v) =>
              v.validatorType == ValidatorType.numeric ||
              v.validatorType == ValidatorType.dimension)
          .firstOrNull;
      final data = numericValidator?.validatorData;
      final minKey = numericValidator?.validatorType == ValidatorType.dimension
          ? 'minValue'
          : 'min';
      final maxKey = numericValidator?.validatorType == ValidatorType.dimension
          ? 'maxValue'
          : 'max';
      _minController = TextEditingController(
        text: data?[minKey]?.toString() ?? '',
      );
      _maxController = TextEditingController(
        text: data?[maxKey]?.toString() ?? '',
      );
    } else {
      _labelController = TextEditingController();
      _selectedWidget = _validWidgets.first;
      _isList = false;
      _isOptional = false;
      _options = [];
      _selectedUnit = null;
      _defaultValue = null;
      _defaultValueController = TextEditingController();
      _minController = TextEditingController();
      _maxController = TextEditingController();
    }
    
    _optionController = TextEditingController();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _optionController.dispose();
    _defaultValueController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnumerated = widget.fieldType == FieldEnum.enumerated || widget.fieldType == FieldEnum.multiEnum;
    final draftColor = context.colors.textSecondary; // Blue-gray "pencil sketch"
    final supportsDefault = _defaultHandler.supportsManualDefault(widget.fieldType);
    
    return Container(
      padding: AppPadding.allSingle,
      child: QuanityaColumn(
        crossAlignment: CrossAxisAlignment.start,
        children: [
          // Header with field type
          _buildHeader(context, draftColor),
          
          VSpace.x1,
          
          // Label input
          QuanityaTextField(
            controller: _labelController,
            labelText: context.l10n.fieldLabelLabel,
            hintText: context.l10n.fieldLabelHint,
            autofocus: !widget.isEditing,
            onChanged: (_) => setState(() {}),
          ),
          
          // Widget type selector (if multiple options)
          if (_validWidgets.length > 1) ...[
            VSpace.x1,
            _buildWidgetSelector(context, draftColor),
          ],
          
          // Options for enumerated fields
          if (isEnumerated) ...[
            VSpace.x1,
            _buildOptionsEditor(context, draftColor),
          ],

          // Unit selector for dimension fields
          if (widget.fieldType == FieldEnum.dimension) ...[
            VSpace.x1,
            _buildUnitSelector(context, draftColor),
          ],

          // Range editor for numeric fields
          if (_isNumericField) ...[
            VSpace.x1,
            _buildRangeEditor(context, draftColor),
          ],

          // Default value editor (for supported types, not for lists)
          if (supportsDefault && !_isList) ...[
            VSpace.x1,
            _buildDefaultValueEditor(context, draftColor),
          ],
          
          VSpace.x1,
          
          // isList toggle
          _buildListToggle(context, draftColor),

          // Optional toggle (text fields only)
          if (widget.fieldType == FieldEnum.text) ...[
            VSpace.x1,
            _buildOptionalToggle(context, draftColor),
          ],

          VSpace.x2,

          // Action buttons
          _buildActions(context),
        ],
      ),
    );
  }

  bool get _isNumericField =>
      widget.fieldType == FieldEnum.integer ||
      widget.fieldType == FieldEnum.float ||
      widget.fieldType == FieldEnum.dimension;

  bool get _rangeRequired => _isNumericField;

  Widget _buildRangeEditor(BuildContext context, Color draftColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.fieldRangeLabel,
          style: context.text.labelMedium?.copyWith(
            color: draftColor,
          ),
        ),
        VSpace.x05,
        QuanityaRow(
          spacing: HSpace.x1,
          start: Expanded(
            child: QuanityaTextField(
              controller: _minController,
              hintText: context.l10n.fieldRangeMinHint,
              keyboardType: widget.fieldType == FieldEnum.integer
                  ? const TextInputType.numberWithOptions(signed: true)
                  : const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
          end: Expanded(
            child: QuanityaTextField(
              controller: _maxController,
              hintText: context.l10n.fieldRangeMaxHint,
              keyboardType: widget.fieldType == FieldEnum.integer
                  ? const TextInputType.numberWithOptions(signed: true)
                  : const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Color draftColor) {
    return QuanityaRow(
      alignment: CrossAxisAlignment.center,
      start: Icon(
        _getFieldIcon(),
        size: AppSizes.iconSmall,
        color: draftColor,
      ),
      middle: Text(
        widget.isEditing
            ? context.l10n.editFieldType(widget.fieldType.displayName)
            : context.l10n.addFieldType(widget.fieldType.displayName),
        style: context.text.titleSmall?.copyWith(
          color: draftColor,
        ),
      ),
    );
  }

  Widget _buildWidgetSelector(BuildContext context, Color draftColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.widgetTypeLabel,
          style: context.text.labelMedium?.copyWith(
            color: draftColor,
          ),
        ),
        VSpace.x05,
        Wrap(
          spacing: AppSizes.space,
          runSpacing: AppSizes.space * 0.5,
          children: _validWidgets.map((w) => _DraftChip(
            label: _getWidgetDisplayName(context, w),
            isSelected: _selectedWidget == w,
            onTap: () => setState(() => _selectedWidget = w),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionsEditor(BuildContext context, Color draftColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.fieldOptionsLabel,
          style: context.text.labelMedium?.copyWith(
            color: draftColor,
          ),
        ),
        VSpace.x05,
        
        // Existing options as chips
        if (_options.isNotEmpty) ...[
          Wrap(
            spacing: AppSizes.space,
            runSpacing: AppSizes.space * 0.5,
            children: _options.map((option) => Chip(
              label: Text(option, style: context.text.bodySmall?.copyWith(
                color: draftColor,
              )),
              deleteIcon: Icon(
                Icons.close, 
                size: AppSizes.iconSmall,
                color: draftColor,
              ),
              onDeleted: () => setState(() => _options.remove(option)),
              backgroundColor: Colors.transparent,
              side: BorderSide(color: draftColor.withValues(alpha: 0.3)),
            )).toList(),
          ),
          VSpace.x05,
        ],
        
        // Add option input
        QuanityaRow(
          spacing: HSpace.x1,
          start: Expanded(
            child: QuanityaTextField(
              controller: _optionController,
              hintText: context.l10n.addOptionHint,
              onSubmitted: (_) => _addOption(),
            ),
          ),
          end: QuanityaIconButton(
            icon: Icons.add_circle_outline,
            color: _optionController.text.trim().isNotEmpty
                ? context.colors.interactableColor
                : draftColor,
            onPressed: _addOption,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSelector(BuildContext context, Color draftColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.fieldUnitLabel,
          style: context.text.labelMedium?.copyWith(
            color: draftColor,
          ),
        ),
        VSpace.x05,
        // Group units by dimension, each in a collapsible fold
        for (final dimension in MeasurementDimension.values)
          NotebookFold(
            initiallyExpanded: _selectedUnit?.measurementDimension == dimension,
            semanticLabel: _getDimensionDisplayName(context, dimension),
            header: Text(
              _getDimensionDisplayName(context, dimension),
              style: context.text.bodySmall?.copyWith(
                color: draftColor.withValues(alpha: 0.6),
              ),
            ),
            child: Wrap(
              spacing: AppSizes.space,
              runSpacing: AppSizes.space * 0.5,
              children: MeasurementUnit.unitsFor(dimension).map((unit) =>
                _DraftChip(
                  label: '${unit.fullName} (${unit.displayName})',
                  isSelected: _selectedUnit == unit,
                  onTap: () => setState(() => _selectedUnit = unit),
                ),
              ).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildListToggle(BuildContext context, Color draftColor) {
    return Semantics(
      toggled: _isList,
      label: context.l10n.accessibilityAllowMultipleValues,
      child: InkWell(
        onTap: () => setState(() => _isList = !_isList),
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: Padding(
        padding: AppPadding.verticalSingle,
        child: QuanityaRow(
          alignment: CrossAxisAlignment.center,
          start: Icon(
            _isList ? Icons.check_box : Icons.check_box_outline_blank,
            size: AppSizes.iconSmall,
            color: _isList 
                ? context.colors.interactableColor 
                : draftColor,
          ),
          middle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.fieldIsListLabel,
                style: context.text.bodyMedium?.copyWith(
                  color: draftColor,
                ),
              ),
              Text(
                context.l10n.fieldIsListHint,
                style: context.text.bodySmall?.copyWith(
                  color: draftColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildOptionalToggle(BuildContext context, Color draftColor) {
    return QuanityaRow(
      alignment: CrossAxisAlignment.center,
      start: Text(
        context.l10n.fieldOptionalLabel,
        style: context.text.bodyMedium?.copyWith(
          color: draftColor,
        ),
      ),
      end: QuanityaToggle(
        value: _isOptional,
        onChanged: (val) => setState(() => _isOptional = val),
        semanticLabel: context.l10n.fieldOptionalLabel,
        activeTrackColor: context.colors.interactableColor,
        activeThumbColor: context.colors.backgroundPrimary,
        inactiveTrackColor: draftColor,
        inactiveThumbColor: context.colors.backgroundPrimary,
      ),
    );
  }

  Widget _buildDefaultValueEditor(BuildContext context, Color draftColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.fieldDefaultValueLabel,
          style: context.text.labelMedium?.copyWith(
            color: draftColor,
          ),
        ),
        VSpace.x025,
        Text(
          context.l10n.fieldDefaultValueQuickLogHint,
          style: context.text.bodySmall?.copyWith(
            color: draftColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        VSpace.x05,
        _buildDefaultValueInput(context, draftColor),
        if (_defaultValueError != null) ...[
          VSpace.x025,
          Text(
            _defaultValueError!,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.errorColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultValueInput(BuildContext context, Color draftColor) {
    return switch (widget.fieldType) {
      FieldEnum.integer || FieldEnum.float || FieldEnum.dimension =>
        _buildNumericDefaultInput(context, draftColor),
      FieldEnum.text =>
        _buildTextDefaultInput(context, draftColor),
      FieldEnum.boolean =>
        _buildBooleanDefaultInput(context, draftColor),
      FieldEnum.datetime =>
        _buildDateTimeDefaultInput(context, draftColor),
      FieldEnum.enumerated =>
        _buildEnumeratedDefaultInput(context, draftColor),
      FieldEnum.reference =>
        const SizedBox.shrink(), // No default for references
      FieldEnum.location =>
        const SizedBox.shrink(), // No default for locations
      FieldEnum.group =>
        const SizedBox.shrink(), // No default for groups
      FieldEnum.multiEnum =>
        const SizedBox.shrink(), // No default for multi-select
    };
  }

  Widget _buildNumericDefaultInput(BuildContext context, Color draftColor) {
    return QuanityaTextField(
      controller: _defaultValueController,
      hintText: context.l10n.fieldDefaultValueHint,
      keyboardType: widget.fieldType == FieldEnum.integer
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {
          if (value.isEmpty) {
            _defaultValue = null;
            _defaultValueError = null;
          } else {
            _defaultValue = _defaultHandler.parseDefault(value, widget.fieldType);
            if (_defaultValue == null) {
              _defaultValueError = widget.fieldType == FieldEnum.integer
                  ? 'Must be a whole number'
                  : 'Must be a number';
            } else {
              _defaultValueError = null;
            }
          }
        });
      },
    );
  }

  Widget _buildTextDefaultInput(BuildContext context, Color draftColor) {
    return QuanityaTextField(
      controller: _defaultValueController,
      hintText: context.l10n.fieldDefaultValueHint,
      onChanged: (value) {
        setState(() {
          _defaultValue = value.isEmpty ? null : value;
          _defaultValueError = null;
        });
      },
    );
  }

  Widget _buildBooleanDefaultInput(BuildContext context, Color draftColor) {
    return Row(
      children: [
        _DraftChip(
          label: context.l10n.booleanTrue,
          isSelected: _defaultValue == true,
          onTap: () => setState(() {
            _defaultValue = _defaultValue == true ? null : true;
            _defaultValueError = null;
          }),
        ),
        HSpace.x1,
        _DraftChip(
          label: context.l10n.booleanFalse,
          isSelected: _defaultValue == false,
          onTap: () => setState(() {
            _defaultValue = _defaultValue == false ? null : false;
            _defaultValueError = null;
          }),
        ),
        HSpace.x2,
        if (_defaultValue != null)
          QuanityaTextButton(
            text: context.l10n.actionClear,
            onPressed: () => setState(() => _defaultValue = null),
          ),
      ],
    );
  }

  Widget _buildDateTimeDefaultInput(BuildContext context, Color draftColor) {
    final hasValue = _defaultValue != null;

    return Semantics(
      button: true,
      label: context.l10n.accessibilitySetDefaultDateTime,
      child: InkWell(
        onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null && context.mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            final dateTime = DateTime(
              date.year, date.month, date.day,
              time.hour, time.minute,
            );
            setState(() {
              _defaultValue = dateTime.toIso8601String();
              _defaultValueController.text = _defaultValueToString(_defaultValue);
              _defaultValueError = null;
            });
          }
        }
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: Container(
        padding: AppPadding.allSingle,
        decoration: BoxDecoration(
          border: Border.all(color: draftColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: AppSizes.iconSmall, color: draftColor),
            HSpace.x1,
            Expanded(
              child: Text(
                hasValue 
                    ? _defaultValueToString(_defaultValue)
                    : context.l10n.fieldDefaultValueHint,
                style: context.text.bodyMedium?.copyWith(
                  color: hasValue ? draftColor : draftColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            if (hasValue)
              QuanityaIconButtonSizes.small(
                icon: Icons.close,
                tooltip: context.l10n.actionClear,
                color: draftColor,
                onPressed: () => setState(() {
                  _defaultValue = null;
                  _defaultValueController.clear();
                }),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildEnumeratedDefaultInput(BuildContext context, Color draftColor) {
    if (_options.isEmpty) {
      return Text(
        context.l10n.fieldDefaultValueAddOptionsFirst,
        style: context.text.bodySmall?.copyWith(
          color: draftColor.withValues(alpha: 0.7),
        ),
      );
    }
    
    return Wrap(
      spacing: AppSizes.space,
      runSpacing: AppSizes.space * 0.5,
      children: _options.map((option) => _DraftChip(
        label: option,
        isSelected: _defaultValue == option,
        onTap: () => setState(() {
          _defaultValue = _defaultValue == option ? null : option;
          _defaultValueError = null;
        }),
      )).toList(),
    );
  }

  String _defaultValueToString(Object? value) {
    if (value == null) return '';
    if (value is String && widget.fieldType == FieldEnum.datetime) {
      try {
        final dt = DateTime.parse(value);
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
               '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return value;
      }
    }
    return value.toString();
  }

  Widget _buildActions(BuildContext context) {
    final canSave = _canSave;
    
    return QuanityaRow(
      alignment: CrossAxisAlignment.center,
      start: QuanityaTextButton(
        text: context.l10n.actionCancel,
        onPressed: widget.onCancel,
      ),
      end: QuanityaTextButton(
        text: widget.isEditing ? context.l10n.actionSave : context.l10n.actionAdd,
        onPressed: canSave ? _save : null,
      ),
    );
  }

  void _addOption() {
    final option = _optionController.text.trim();
    if (option.isNotEmpty && !_options.contains(option)) {
      setState(() {
        _options.add(option);
        _optionController.clear();
      });
    }
  }

  bool get _canSave {
    final label = _labelController.text.trim();
    if (label.isEmpty) return false;

    // Enumerated and multiEnum fields need at least one option
    if ((widget.fieldType == FieldEnum.enumerated || widget.fieldType == FieldEnum.multiEnum) && _options.isEmpty) {
      return false;
    }

    // Dimension fields need a unit
    if (widget.fieldType == FieldEnum.dimension && _selectedUnit == null) {
      return false;
    }

    // Range validation for numeric fields
    if (_isNumericField) {
      final minText = _minController.text.trim();
      final maxText = _maxController.text.trim();

      // Non-empty values must be valid numbers
      if (minText.isNotEmpty && num.tryParse(minText) == null) return false;
      if (maxText.isNotEmpty && num.tryParse(maxText) == null) return false;

      // If both provided, min must be less than max
      if (minText.isNotEmpty && maxText.isNotEmpty) {
        final min = num.parse(minText);
        final max = num.parse(maxText);
        if (min >= max) return false;
      }
    }

    return true;
  }

  List<FieldValidator> _buildValidators() {
    final validators = <FieldValidator>[];

    // Add optional validator for text fields
    if (_isOptional) {
      validators.add(FieldValidator.create(
        validatorType: ValidatorType.optional,
        validatorData: {},
      ));
    }

    if (!_isNumericField) return validators;

    final minText = _minController.text.trim();
    final maxText = _maxController.text.trim();

    // Resolve values: use defaults for slider/stepper if empty
    num? minVal = minText.isNotEmpty ? num.parse(minText) : null;
    num? maxVal = maxText.isNotEmpty ? num.parse(maxText) : null;

    if (_rangeRequired) {
      minVal ??= 0;
      maxVal ??= 10;
    }

    // No values = no numeric validator needed
    if (minVal == null && maxVal == null) return validators;

    final isDimension = widget.fieldType == FieldEnum.dimension;
    validators.add(FieldValidator.create(
        validatorType:
            isDimension ? ValidatorType.dimension : ValidatorType.numeric,
        validatorData: isDimension
            ? {
                if (minVal != null) 'minValue': minVal,
                if (maxVal != null) 'maxValue': maxVal,
              }
            : {
                if (minVal != null) 'min': minVal,
                if (maxVal != null) 'max': maxVal,
              },
      ));
    return validators;
  }

  void _save() {
    if (!_canSave) return;

    final label = _labelController.text.trim();

    // Clear default value if switching to list mode
    final effectiveDefault = _isList ? null : _defaultValue;

    final validators = _buildValidators();

    final field = widget.isEditing
        ? widget.existingField!.copyWith(
            label: label,
            uiElement: _selectedWidget,
            isList: _isList,
            unit: widget.fieldType == FieldEnum.dimension ? _selectedUnit : null,
            options: (widget.fieldType == FieldEnum.enumerated || widget.fieldType == FieldEnum.multiEnum) ? _options : null,
            defaultValue: effectiveDefault,
            validators: validators,
          )
        : TemplateField.create(
            type: widget.fieldType,
            label: label,
            uiElement: _selectedWidget,
            isList: _isList,
            unit: widget.fieldType == FieldEnum.dimension ? _selectedUnit : null,
            options: (widget.fieldType == FieldEnum.enumerated || widget.fieldType == FieldEnum.multiEnum) ? _options : null,
            defaultValue: effectiveDefault,
            validators: validators,
          );

    widget.onSave(field);
  }

  IconData _getFieldIcon() {
    return switch (widget.fieldType) {
      FieldEnum.integer => Icons.numbers,
      FieldEnum.float => Icons.numbers,
      FieldEnum.text => Icons.text_fields,
      FieldEnum.boolean => Icons.toggle_on,
      FieldEnum.datetime => Icons.calendar_today,
      FieldEnum.enumerated => Icons.list,
      FieldEnum.dimension => Icons.straighten,
      FieldEnum.reference => Icons.link,
      FieldEnum.location => Icons.location_on,
      FieldEnum.group => Icons.dashboard,
      FieldEnum.multiEnum => Icons.checklist,
    };
  }

  String _getDimensionDisplayName(BuildContext context, MeasurementDimension dimension) {
    return switch (dimension) {
      MeasurementDimension.mass => context.l10n.dimensionMass,
      MeasurementDimension.length => context.l10n.dimensionLength,
      MeasurementDimension.volume => context.l10n.dimensionVolume,
      MeasurementDimension.time => context.l10n.dimensionTime,
      MeasurementDimension.temperature => context.l10n.dimensionTemperature,
      MeasurementDimension.speed => context.l10n.dimensionSpeed,
      MeasurementDimension.energy => context.l10n.dimensionEnergy,
      MeasurementDimension.frequency => context.l10n.dimensionFrequency,
    };
  }

  String _getWidgetDisplayName(BuildContext context, UiElementEnum widget) {
    return switch (widget) {
      UiElementEnum.slider => context.l10n.widgetSlider,
      UiElementEnum.stepper => context.l10n.widgetStepper,
      UiElementEnum.textField => context.l10n.widgetTextField,
      UiElementEnum.textArea => context.l10n.widgetTextArea,
      UiElementEnum.dropdown => context.l10n.widgetDropdown,
      UiElementEnum.radio => context.l10n.widgetRadio,
      UiElementEnum.chips => context.l10n.widgetChips,
      UiElementEnum.toggleSwitch => context.l10n.widgetToggleSwitch,
      UiElementEnum.checkbox => context.l10n.widgetCheckbox,
      UiElementEnum.datePicker => context.l10n.widgetDatePicker,
      UiElementEnum.timePicker => context.l10n.widgetTimePicker,
      UiElementEnum.datetimePicker => context.l10n.widgetDatetimePicker,
      UiElementEnum.searchField => context.l10n.widgetSearchField,
      UiElementEnum.locationPicker => context.l10n.widgetLocationPicker,
      UiElementEnum.timer => context.l10n.widgetTimer,
    };
  }
}


/// Simple chip for draft state - all in blue-gray "pencil" color.
/// Selected state just gets a border, no ink black.
class _DraftChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DraftChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PenCircledChip(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}
