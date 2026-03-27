import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../logic/templates/enums/field_enum.dart';
import '../../../../logic/templates/enums/field_enum_extensions.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/structures/column.dart';
import '../../../../design_system/structures/group.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_palette.dart';
import '../../../../design_system/widgets/quanitya_text_field.dart';
import '../../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../../logic/templates/models/shared/template_field.dart';
import '../../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../../design_system/widgets/quanitya/generatable/quanitya_toggle.dart';
import '../../cubits/editor/template_editor_cubit.dart';
import '../../cubits/editor/template_editor_state.dart';
import 'inline_field_editor.dart';

/// List of fields in the template with inline editing and grouping.
///
/// Normal mode: edit + delete icons per field.
/// Group mode: link icons for selecting fields to group.
class FieldEditorList extends StatefulWidget {
  const FieldEditorList({super.key});

  @override
  State<FieldEditorList> createState() => _FieldEditorListState();
}

class _FieldEditorListState extends State<FieldEditorList> {
  bool _isGroupMode = false;
  final Set<String> _selectedFieldIds = {};

  void _exitGroupMode() {
    setState(() {
      _isGroupMode = false;
      _selectedFieldIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      buildWhen: (p, c) => p.fields != c.fields,
      builder: (context, state) {
        _pruneStaleState(state.fields);

        if (state.fields.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Group mode toggle (only when 2+ non-group fields exist)
            if (state.fields.where((f) => f.type != FieldEnum.group).length >= 2)
              _buildGroupModeToggle(context),

            // Field list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.fields.length,
              separatorBuilder: (_, _) => VSpace.x1,
              itemBuilder: (context, index) {
                final field = state.fields[index];

                if (field.type == FieldEnum.group) {
                  return _buildGroupItem(context, field);
                }

                return _buildFieldItem(context, field);
              },
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Group mode bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildGroupModeToggle(BuildContext context) {
    final count = _selectedFieldIds.length;

    return Padding(
      padding: AppPadding.verticalSingle,
      child: Row(
        children: [
          Text(
            context.l10n.groupModeTooltip,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          HSpace.x1,
          QuanityaToggle(
            value: _isGroupMode,
            onChanged: (on) {
              if (on) {
                setState(() => _isGroupMode = true);
              } else {
                _exitGroupMode();
              }
            },
            semanticLabel: context.l10n.groupModeTooltip,
            activeTrackColor: context.colors.interactableColor,
            activeThumbColor: context.colors.backgroundPrimary,
            inactiveTrackColor: context.colors.textSecondary,
            inactiveThumbColor: context.colors.backgroundPrimary,
          ),
          if (_isGroupMode && count >= 2) ...[
            const Spacer(),
            QuanityaTextButton(
              text: context.l10n.groupFieldsAction(count),
              onPressed: () => _showGroupLabelDialog(context),
            ),
          ],
        ],
      ),
    );
  }

  void _showGroupLabelDialog(BuildContext context) {
    final controller = TextEditingController();
    final cubit = context.read<TemplateEditorCubit>();

    void confirmGroup(BuildContext sheetContext) {
      final label = controller.text.trim();
      if (label.isNotEmpty) {
        cubit.groupFields(_selectedFieldIds.toList(), label);
        _exitGroupMode();
        Navigator.pop(sheetContext);
      }
    }

    LooseInsertSheet.show(
      context: context,
      title: context.l10n.groupLabelTitle,
      builder: (sheetContext) => Padding(
        padding: AppPadding.allSingle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuanityaTextField(
              controller: controller,
              hintText: context.l10n.groupLabelHint,
              autofocus: true,
              onSubmitted: (_) => confirmGroup(sheetContext),
            ),
            VSpace.x2,
            Align(
              alignment: Alignment.centerRight,
              child: QuanityaTextButton(
                text: context.l10n.groupFieldsConfirm,
                onPressed: () => confirmGroup(sheetContext),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────────────
  // Field items
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFieldItem(BuildContext context, TemplateField field) {
    return QuanityaGroup(
      child: _buildFieldContent(
        context: context,
        field: field,
        trailing: _isGroupMode
            ? _buildGroupModeTrailing(context, field)
            : _buildNormalTrailing(context, field),
      ),
    );
  }

  /// Normal mode: edit + delete
  Widget _buildNormalTrailing(BuildContext context, TemplateField field) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        QuanityaIconButton(
          onPressed: () => _showEditFieldSheet(context, field),
          icon: Icons.edit,
          color: context.colors.interactableColor,
        ),
        if (context.read<TemplateEditorCubit>().state.template == null)
          QuanityaIconButton(
            onPressed: () => _showDeleteConfirmation(context, field),
            icon: Icons.delete_outline,
            color: context.colors.destructiveColor,
          ),
      ],
    );
  }

  /// Group mode: toggle per field
  Widget _buildGroupModeTrailing(BuildContext context, TemplateField field) {
    final isSelected = _selectedFieldIds.contains(field.id);
    return QuanityaToggle(
      value: isSelected,
      onChanged: (_) => _toggleSelection(field.id),
      semanticLabel: field.label,
      activeTrackColor: context.colors.interactableColor,
      activeThumbColor: context.colors.backgroundPrimary,
      inactiveTrackColor: context.colors.textSecondary,
      inactiveThumbColor: context.colors.backgroundPrimary,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Group field item (squircle border with sub-fields)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildGroupItem(BuildContext context, TemplateField group) {
    final subFields = group.subFields?.where((f) => !f.isDeleted).toList() ?? [];
    final borderColor = context.colors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: AppSizes.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppPadding.allSingle,
            child: QuanityaRow(
              alignment: CrossAxisAlignment.center,
              start: Text(
                group.label,
                style: context.text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              end: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.allowMultipleLabel,
                    style: context.text.bodySmall?.copyWith(
                      color: borderColor,
                    ),
                  ),
                  HSpace.x05,
                  QuanityaToggle(
                    value: group.isList,
                    onChanged: (_) {
                      final updated = group.copyWith(isList: !group.isList);
                      context.read<TemplateEditorCubit>().updateField(group.id, updated);
                    },
                    semanticLabel: context.l10n.allowMultipleLabel,
                    activeTrackColor: context.colors.interactableColor,
                    activeThumbColor: context.colors.backgroundPrimary,
                    inactiveTrackColor: borderColor,
                    inactiveThumbColor: context.colors.backgroundPrimary,
                  ),
                  HSpace.x1,
                  QuanityaTextButton(
                    text: context.l10n.ungroupAction,
                    onPressed: () => context.read<TemplateEditorCubit>().ungroupField(group.id),
                  ),
                ],
              ),
            ),
          ),
          for (int i = 0; i < subFields.length; i++) ...[
            if (i > 0)
              Divider(
                height: AppSizes.borderWidth,
                color: borderColor.withValues(alpha: 0.15),
              ),
            QuanityaGroup(
              child: _buildFieldContent(
                context: context,
                field: subFields[i],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared field content
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFieldContent({
    required BuildContext context,
    required TemplateField field,
    Widget? trailing,
  }) {
    final parts = <String>[
      field.type.displayName,
      if (field.unit != null) field.unit!.displayName,
      if (field.uiElement != null)
        field.uiElement!.displayName(context),
      if (field.isList) context.l10n.fieldIsListLabel,
    ];
    final subtitle = parts.join(' · ');

    return QuanityaRow(
      spacing: HSpace.x2,
      alignment: CrossAxisAlignment.center,
      start: Icon(
        field.type.icon,
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
          if ((field.type == FieldEnum.enumerated || field.type == FieldEnum.multiEnum) &&
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
          field.defaultValue != null
              ? Text(
                  '${context.l10n.fieldDefaultValueLabelShort}: ${_formatDefaultValue(context, field)}',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textSecondary.withValues(alpha: 0.7),
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
      end: trailing ?? const SizedBox.shrink(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Selection & state
  // ─────────────────────────────────────────────────────────────────────────

  void _toggleSelection(String fieldId) {
    setState(() {
      if (_selectedFieldIds.contains(fieldId)) {
        _selectedFieldIds.remove(fieldId);
      } else {
        _selectedFieldIds.add(fieldId);
      }
    });
  }

  void _pruneStaleState(List<TemplateField> fields) {
    final fieldIds = fields.map((f) => f.id).toSet();
    _selectedFieldIds.removeWhere((id) => !fieldIds.contains(id));
  }

  void _showEditFieldSheet(BuildContext context, TemplateField field) {
    final cubit = context.read<TemplateEditorCubit>();
    LooseInsertSheet.show(
      context: context,
      title: context.l10n.editFieldType(field.type.displayName),
      builder: (sheetContext) => SingleChildScrollView(
        child: InlineFieldEditor(
          fieldType: field.type,
          existingField: field,
          onSave: (updatedField) {
            cubit.updateField(field.id, updatedField);
            Navigator.pop(sheetContext);
          },
          onCancel: () => Navigator.pop(sheetContext),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _formatDefaultValue(BuildContext context, TemplateField field) {
    final value = field.defaultValue;
    if (value == null) return '';

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
