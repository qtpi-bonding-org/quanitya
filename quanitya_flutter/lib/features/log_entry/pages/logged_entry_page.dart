import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../app_router.dart';
import '../../../data/dao/log_entry_query_dao.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/structures/column.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/detail/entry_detail_cubit.dart';

/// Logged Entry Page - Read-only view of a logged entry.
/// 
/// Shows entry data with option to edit, delete, and view insights.
class LoggedEntryPage extends StatelessWidget {
  final LogEntryWithContext entryWithContext;

  const LoggedEntryPage({
    super.key,
    required this.entryWithContext,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<EntryDetailCubit>()..initWithEntry(entryWithContext),
      child: BlocConsumer<EntryDetailCubit, EntryDetailState>(
        listener: (context, state) {
          // Navigate back after successful delete
          if (state.status == UiFlowStatus.success && 
              state.lastOperation == EntryDetailOperation.delete) {
            AppNavigation.back(context);
          }
        },
        builder: (context, state) {
          final entry = state.entry?.entry ?? entryWithContext.entry;
          final template = state.entry?.template ?? entryWithContext.template;
          final aesthetics = state.entry?.aesthetics ?? entryWithContext.aesthetics;
          
          // Format timestamp
          final timestamp = entry.occurredAt ?? entry.scheduledFor ?? DateTime.now();
          final dateString = DateFormat('EEEE, MMMM d, yyyy').format(timestamp);
          final timeString = DateFormat('h:mm a').format(timestamp);
          
          // Get emoji
          final emoji = aesthetics?.emoji ?? '📝';

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: QuanityaIconButton(
                icon: Icons.arrow_back,
                onPressed: () => AppNavigation.back(context),
              ),
              actions: [
                // Visualization button
                QuanityaIconButton(
                  icon: Icons.bar_chart,
                  tooltip: context.l10n.tooltipViewInsights,
                  onPressed: () {
                    AppNavigation.toVisualization(context, template.id);
                  },
                ),
                // Edit button
                QuanityaIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: context.l10n.tooltipEditTemplate,
                  onPressed: () {
                            AppNavigation.toLoggedEntryEditor(context, state.entry ?? entryWithContext);
                  },
                ),
                // Delete button
                QuanityaIconButton(
                  icon: Icons.delete_outline,
                  tooltip: context.l10n.actionDelete,
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: AppPadding.page,
              child: QuanityaColumn(
                crossAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Emoji + Template Name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        emoji,
                        style: TextStyle(fontSize: AppSizes.fontMassive),
                      ),
                      HSpace.x2,
                      Expanded(
                        child: QuanityaColumn(
                          crossAlignment: CrossAxisAlignment.start,
                          spacing: VSpace.x05,
                          children: [
                            Text(
                              template.name,
                              style: context.text.headlineMedium,
                            ),
                            Text(
                              dateString,
                              style: context.text.bodyMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  VSpace.x1,
                  
                  // Time badge
                  Text(
                    timeString,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  
                  VSpace.x4,
                  
                  // Divider
                  Divider(
                    color: context.colors.textSecondary.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  
                  VSpace.x3,
                  
                  // Entry Data Fields
                  ...entry.data.entries.map((fieldEntry) {
                    return _FieldDisplay(
                      fieldId: fieldEntry.key,
                      value: fieldEntry.value,
                      template: template,
                    );
                  }),
                  
                  // If no data
                  if (entry.data.isEmpty)
                    Center(
                      child: Padding(
                        padding: AppPadding.verticalDouble,
                        child: Text(
                          'No data recorded',
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.actionDelete,
      message: context.l10n.confirmDeleteEntry,
      confirmText: context.l10n.actionDelete,
      isDestructive: true,
      onConfirm: () => context.read<EntryDetailCubit>().deleteEntry(),
    );
  }
}

/// Displays a single field value in read-only format.
class _FieldDisplay extends StatelessWidget {
  final String fieldId;
  final dynamic value;
  final dynamic template;

  const _FieldDisplay({
    required this.fieldId,
    required this.value,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    // Try to find field label from template
    String label = fieldId;
    try {
      final field = template.fields.firstWhere(
        (f) => f.id == fieldId,
        orElse: () => null,
      );
      if (field != null) {
        label = field.label;
      }
    } catch (_) {
      // Keep fieldId as label
    }

    return Padding(
      padding: AppPadding.verticalSingle,
      child: QuanityaColumn(
        crossAlignment: CrossAxisAlignment.start,
        spacing: VSpace.x05,
        children: [
          // Field label (metadata style)
          Text(
            label.toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          // Field value (header style for emphasis)
          Text(
            _formatValue(value),
            style: context.text.headlineSmall,
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? '✓ Yes' : '✗ No';
    if (value is DateTime) return DateFormat('MMM d, yyyy h:mm a').format(value);
    if (value is double) return value.toStringAsFixed(1);
    if (value is Map && value.containsKey('value')) {
      // Dimension type
      final v = value['value'];
      final unit = value['unit'] ?? '';
      return '$v $unit';
    }
    return value.toString();
  }
}
