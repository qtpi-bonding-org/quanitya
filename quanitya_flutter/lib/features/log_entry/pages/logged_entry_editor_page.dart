import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dao/log_entry_query_dao.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../templates/widgets/shared/template_preview.dart';
import '../cubits/detail/entry_detail_cubit.dart';

/// Logged Entry Editor Page - Edit an existing log entry using TemplatePreview.
class LoggedEntryEditorPage extends StatefulWidget {
  final LogEntryWithContext entryWithContext;

  const LoggedEntryEditorPage({
    super.key,
    required this.entryWithContext,
  });

  @override
  State<LoggedEntryEditorPage> createState() => _LoggedEntryEditorPageState();
}

class _LoggedEntryEditorPageState extends State<LoggedEntryEditorPage> {
  late Map<String, dynamic> _values;

  @override
  void initState() {
    super.initState();
    _values = Map<String, dynamic>.from(widget.entryWithContext.entry.data);
  }

  void _updateValues(Map<String, dynamic> newValues) {
    setState(() {
      _values = newValues;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<EntryDetailCubit>()
        ..initWithEntry(widget.entryWithContext),
      child: BlocConsumer<EntryDetailCubit, EntryDetailState>(
        listener: (context, state) {
          if (state.status == UiFlowStatus.success &&
              state.lastOperation == EntryDetailOperation.update) {
            context.pop(true);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(context.l10n.actionEdit),
              leading: QuanityaIconButton(
                icon: Icons.close,
                onPressed: () => context.pop(),
              ),
            ),
            body: Padding(
              padding: AppPadding.page,
              child: TemplatePreview(
                template: widget.entryWithContext.template,
                aesthetics: widget.entryWithContext.aesthetics,
                initialValues: _values,
                onValuesChanged: _updateValues,
                actions: [
                  TemplatePreviewAction.secondary(
                    label: context.l10n.actionCancel,
                    icon: Icons.close,
                    onPressed: () => context.pop(),
                  ),
                  TemplatePreviewAction.primary(
                    label: context.l10n.actionSave,
                    icon: Icons.save,
                    onPressed: state.isLoading ? () {} : () => _saveEntry(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveEntry(BuildContext context) {
    final entry = widget.entryWithContext.entry;
    final updatedEntry = entry.copyWith(
      occurredAt: entry.occurredAt ?? DateTime.now(),
      data: _values,
    );
    context.read<EntryDetailCubit>().updateEntry(updatedEntry);
  }
}
