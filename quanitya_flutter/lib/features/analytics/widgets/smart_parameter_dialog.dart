import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../../logic/analytics/enums/calculation.dart';
import '../../../logic/analytics/models/matrix_vector_scalar/operation_registry.dart';
import '../../../logic/analytics/models/matrix_vector_scalar/operation_definition.dart';
import '../../../logic/analytics/models/matrix_vector_scalar/analysis_data_type.dart';
import '../../../support/extensions/context_extensions.dart';
import 'dynamic_field_selector.dart';

class SmartParameterDialog extends StatefulWidget {
  final Calculation operation;
  final AnalysisDataType inputType;
  final Set<String> availableContextKeys;
  final List<String> availableFields;
  final Function(Map<String, dynamic> params) onConfirm;
  final bool isParallel;
  
  const SmartParameterDialog({
    super.key,
    required this.operation,
    required this.inputType,
    required this.availableContextKeys,
    required this.availableFields,
    required this.onConfirm,
    this.isParallel = false,
  });
  
  @override
  State<SmartParameterDialog> createState() => _SmartParameterDialogState();
}

class _SmartParameterDialogState extends State<SmartParameterDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _params = {};
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final definition = OperationRegistry.instance.getDefinition(widget.operation)!;

    return AlertDialog(
      title: Text(l10n.paramDialogConfigureTitle(definition.label)),
      content: Container(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operation description
              Container(
                padding: AppPadding.allSingle,
                decoration: BoxDecoration(
                  color: QuanityaPalette.primary.interactableColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  definition.description,
                  style: context.text.bodyMedium,
                ),
              ),
              
              VSpace.x2,
              
              // Multi-input operations: show context key selectors
              if (definition.inputCount > 1 && !widget.isParallel)
                ..._buildInputKeySelectors(definition),
              
              // Required parameters
              ...definition.requiredParams.map((param) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _buildParameterField(param, definition),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        QuanityaTextButton(
          text: l10n.actionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        QuanityaTextButton(
          text: l10n.paramDialogAddOperation,
          onPressed: _canConfirm() ? _confirm : null,
        ),
      ],
    );
  }
  
  List<Widget> _buildInputKeySelectors(OperationDefinition definition) {
    final l10n = AppLocalizations.of(context)!;
    final inputKeys = <Widget>[];

    for (int i = 0; i < definition.inputCount; i++) {
      inputKeys.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paramDialogInputLabel(i + 1),
              style: context.text.bodySmall?.copyWith(
                color: QuanityaPalette.primary.textSecondary,
              ),
            ),
            VSpace.x025,
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: l10n.paramDialogSelectDataSource,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
              ),
              items: widget.availableContextKeys.map((key) {
                return DropdownMenuItem(
                  value: key,
                  child: Text(key),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _params['inputKey$i'] = value;
                });
              },
              validator: (value) {
                if (value == null) return l10n.paramDialogRequired;
                return null;
              },
            ),
            VSpace.x1,
          ],
        ),
      );
    }
    
    return inputKeys;
  }
  
  Widget _buildParameterField(String param, OperationDefinition definition) {
    final l10n = AppLocalizations.of(context)!;
    return switch (param) {
      'fieldName' => DynamicFieldSelector(
          availableFields: widget.availableFields,
          onFieldChanged: (value) {
            setState(() {
              _params['fieldName'] = value;
            });
          },
        ),
      'windowDays' => _buildNumberField(param, l10n.paramDialogWindowSize, 1, 365),
      'percentile' => _buildNumberField(param, l10n.paramDialogPercentile, 0, 100),
      'threshold' => _buildNumberField(param, l10n.paramDialogThreshold, null, null),
      'operator' => _buildOperatorSelector(),
      'value' => _buildNumberField(param, l10n.paramDialogValue, null, null),
      _ => _buildGenericField(param),
    };
  }
  
  Widget _buildNumberField(String param, String label, double? min, double? max) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            color: QuanityaPalette.primary.textSecondary,
          ),
        ),
        VSpace.x025,
        TextFormField(
          decoration: InputDecoration(
            hintText: min != null && max != null ? '$min - $max' : l10n.paramDialogEnterNumber,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final number = double.tryParse(value);
            if (number != null) {
              setState(() {
                _params[param] = number;
              });
            }
          },
          validator: (value) {
            if (value?.isEmpty ?? true) return l10n.paramDialogRequired;
            final number = double.tryParse(value!);
            if (number == null) return l10n.paramDialogMustBeNumber;
            if (min != null && number < min) return l10n.paramDialogMustBeAtLeast('$min');
            if (max != null && number > max) return l10n.paramDialogMustBeAtMost('$max');
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildOperatorSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.paramDialogOperator,
          style: context.text.bodySmall?.copyWith(
            color: QuanityaPalette.primary.textSecondary,
          ),
        ),
        VSpace.x025,
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
          items: ['>', '<', '>=', '<=', '==', '!='].map((op) {
            return DropdownMenuItem(value: op, child: Text(op));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _params['operator'] = value;
            });
          },
          validator: (value) => value == null ? l10n.paramDialogRequired : null,
        ),
      ],
    );
  }
  
  Widget _buildGenericField(String param) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          param.replaceAll('_', ' ').toUpperCase(),
          style: context.text.bodySmall?.copyWith(
            color: QuanityaPalette.primary.textSecondary,
          ),
        ),
        VSpace.x025,
        TextFormField(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _params[param] = value;
            });
          },
          validator: (value) {
            if (value?.isEmpty ?? true) return l10n.paramDialogRequired;
            return null;
          },
        ),
      ],
    );
  }
  
  bool _canConfirm() {
    final definition = OperationRegistry.instance.getDefinition(widget.operation)!;
    
    // Check multi-input requirements (skip for parallel operations)
    if (definition.inputCount > 1 && !widget.isParallel) {
      for (int i = 0; i < definition.inputCount; i++) {
        if (_params['inputKey$i'] == null) return false;
      }
    }
    
    // Check required parameters
    for (final param in definition.requiredParams) {
      if (_params[param] == null) return false;
    }
    
    return true;
  }
  
  void _confirm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Convert multi-input keys to inputKeys list (skip for parallel)
      final definition = OperationRegistry.instance.getDefinition(widget.operation)!;
      if (definition.inputCount > 1 && !widget.isParallel) {
        final inputKeys = <String>[];
        for (int i = 0; i < definition.inputCount; i++) {
          inputKeys.add(_params['inputKey$i']);
          _params.remove('inputKey$i');
        }
        _params['inputKeys'] = inputKeys;
      }
      
      widget.onConfirm(_params);
      Navigator.of(context).pop();
    }
  }
}