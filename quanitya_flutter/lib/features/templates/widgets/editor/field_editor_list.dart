import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../logic/templates/enums/field_enum.dart';
import '../../../../logic/templates/enums/field_enum_extensions.dart';
import '../../../../logic/templates/enums/ui_element_enum.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/group.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../logic/templates/models/shared/template_field.dart';
import '../../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';
import 'inline_field_editor.dart';

/// List of fields in the template with inline editing capabilities.
///
/// Tapping edit expands the field row into an inline editor.
/// Fits the manuscript aesthetic - editing feels like writing.
class FieldEditorList extends StatefulWidget {
  const FieldEditorList({super.key});

  @override
  State<FieldEditorList> createState() => _FieldEditorListState();
}

class _FieldEditorListState extends State<FieldEditorList> {
  /// ID of field currently being edited (null if none)
  String? _editingFieldId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      builder: (context, state) {
        if (state.fields.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.fields.length,
          separatorBuilder: (_, _) => VSpace.x1,
          itemBuilder: (context, index) {
            final field = state.fields[index];
            final isEditing = _editingFieldId == field.id;

            if (isEditing) {
              return InlineFieldEditor(
                fieldType: field.type,
                existingField: field,
                onSave: (updatedField) {
                  context.read<TemplateEditorCubit>().updateField(
                    field.id,
                    updatedField,
                  );
                  setState(() => _editingFieldId = null);
                },
                onCancel: () => setState(() => _editingFieldId = null),
              );
            }

            return _buildFieldItem(context, field);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: QuanityaColumn(
        crossAlignment: CrossAxisAlignment.center,
        children: [
          VSpace.x2,
          Text(
            context.l10n.noFieldsTitle,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          Text(
            context.l10n.noFieldsMessage,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldItem(BuildContext context, TemplateField field) {
    // Build subtitle: "Integer · Slider · List" or "Measurement · kg · Stepper"
    final parts = <String>[
      field.type.displayName,
      if (field.unit != null) field.unit!.displayName,
      if (field.uiElement != null)
        _getWidgetDisplayName(context, field.uiElement!),
      if (field.isList) context.l10n.fieldIsListLabel,
    ];
    final subtitle = parts.join(' · ');

    return QuanityaGroup(
      child: QuanityaRow(
        spacing: HSpace.x2,
        alignment: CrossAxisAlignment.center,
        start: Icon(
          _getFieldIcon(field),
          size: AppSizes.size20,
          color: context.colors.textSecondary,
        ),
        middle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: context.text.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: context.text.labelMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            // Show options for enumerated fields
            if (field.type == FieldEnum.enumerated &&
                field.options != null &&
                field.options!.isNotEmpty)
              Text(
                field.options!.join(', '),
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.textSecondary.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // Show default value if set, otherwise show warning icon
            field.defaultValue != null
                ? Text(
                    '${context.l10n.fieldDefaultValueLabel.replaceAll(' (optional)', '')}: ${_formatDefaultValue(context, field)}',
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.textSecondary.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        size: AppSizes.size16,
                        color: context.colors.cautionColor,
                      ),
                      HSpace.x05,
                      Expanded(
                        child: Text(
                          context.l10n.fieldNoDefaultWarning,
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.cautionColor,
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
        end: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuanityaIconButton(
              onPressed: () => setState(() => _editingFieldId = field.id),
              icon: Icons.edit,
              color: context.colors.interactableColor,
            ),
            QuanityaIconButton(
              onPressed: () => _showDeleteConfirmation(context, field),
              icon: Icons.delete_outline,
              color: context.colors.destructiveColor,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDefaultValue(BuildContext context, TemplateField field) {
    final value = field.defaultValue;
    if (value == null) return '';

    // Format based on field type
    return switch (field.type) {
      FieldEnum.boolean => value == true ? context.l10n.booleanTrue : context.l10n.booleanFalse,
      FieldEnum.datetime => _formatDateTime(value),
      _ => value.toString(),
    };
  }

  String _formatDateTime(Object value) {
    if (value is! String) return value.toString();
    try {
      final dt = DateTime.parse(value);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  IconData _getFieldIcon(TemplateField field) {
    return switch (field.type) {
      FieldEnum.integer => Icons.numbers,
      FieldEnum.float => Icons.numbers,
      FieldEnum.text => Icons.text_fields,
      FieldEnum.boolean => Icons.toggle_on,
      FieldEnum.datetime => Icons.calendar_today,
      FieldEnum.enumerated => Icons.list,
      FieldEnum.dimension => Icons.straighten,
      FieldEnum.reference => Icons.link,
      FieldEnum.location => Icons.location_on,
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

  void _showDeleteConfirmation(BuildContext context, TemplateField field) {
    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.deleteFieldTitle,
      message: context.l10n.deleteFieldMessage(field.label),
      confirmText: context.l10n.actionDelete,
      isDestructive: true,
      onConfirm: () {
        context.read<TemplateEditorCubit>().removeField(field.id);
      },
    );
  }
}
