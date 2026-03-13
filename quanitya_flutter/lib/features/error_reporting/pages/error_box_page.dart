import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya/generatable/quanitya_toggle.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../cubits/error_box_cubit.dart';
import '../cubits/error_box_state.dart';
import '../widgets/error_entry_card.dart';
import '../../outbox/widgets/outbox_tab_content.dart';

/// Error reports content — embedded in [NotebookShell] via PostagePage.
class ErrorsTabContent extends StatelessWidget {
  const ErrorsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ErrorBoxCubit, ErrorBoxState>(
      builder: (context, state) {
        return OutboxTabContent(
          isEmpty: state.unsentErrors.isEmpty,
          emptyState: OutboxEmptyState(
            icon: Icons.bug_report_outlined,
            title: context.l10n.errorBoxNoReports,
            description: context.l10n.errorBoxNoReportsDescription,
          ),
          banner: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutboxPrivacyBanner(text: context.l10n.errorBoxPrivacyBanner),
              _AutoSendToggle(),
            ],
          ),
          content: ListView.separated(
            padding: AppPadding.page,
            itemCount: state.unsentErrors.length,
            separatorBuilder: (context, index) => VSpace.x3,
            itemBuilder: (context, index) {
              final error = state.unsentErrors[index];
              return ErrorEntryCard(
                error: error.errorData,
                occurrenceCount: error.occurrenceCount,
                onSend: () => _sendAndPromptClear(context, error.id),
                onDelete: () => context.read<ErrorBoxCubit>().deleteError(error.id),
              );
            },
          ),
          bottomAction: _BottomActions(),
        );
      },
    );
  }

  Future<void> _sendAndPromptClear(BuildContext context, String errorId) async {
    final cubit = context.read<ErrorBoxCubit>();
    await cubit.sendOne(errorId);

    if (!context.mounted) return;

    final state = cubit.state;
    if (state.status == UiFlowStatus.success &&
        state.lastOperation == ErrorBoxOperation.sendOne) {
      QuanityaConfirmationDialog.show(
        context: context,
        title: context.l10n.errorBoxClearSentTitle,
        message: context.l10n.errorBoxClearSentMessage,
        confirmText: context.l10n.errorBoxClearAction,
        onConfirm: () => cubit.deleteError(errorId),
      );
    }
  }
}

class _AutoSendToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ErrorBoxCubit, ErrorBoxState>(
      builder: (context, state) {
        return Padding(
          padding: AppPadding.page,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.errorBoxAutoSend,
                      style: context.text.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                    VSpace.x05,
                    Text(
                      context.l10n.errorBoxAutoSendDescription,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              QuanityaToggle(
                value: state.autoSendEnabled,
                onChanged: (value) =>
                    context.read<ErrorBoxCubit>().toggleAutoSend(value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ErrorBoxCubit, ErrorBoxState>(
      builder: (context, state) {
        return Padding(
          padding: AppPadding.allDouble,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: QuanityaTextButton(
                    text: context.l10n.errorBoxClearAll,
                    isDestructive: true,
                    onPressed: () => _confirmClearAll(context),
                  ),
                ),
                HSpace.x3,
                Expanded(
                  child: QuanityaTextButton(
                    text: context.l10n.errorBoxSendAll(state.unsentErrors.length),
                    onPressed: state.status == UiFlowStatus.loading
                        ? null
                        : () => _sendAndPromptClear(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendAndPromptClear(BuildContext context) async {
    final cubit = context.read<ErrorBoxCubit>();
    await cubit.sendAll();

    if (!context.mounted) return;

    final state = cubit.state;
    if (state.status == UiFlowStatus.success &&
        state.lastOperation == ErrorBoxOperation.sendAll &&
        state.lastSentIds.isNotEmpty) {
      final sentIds = state.lastSentIds;
      QuanityaConfirmationDialog.show(
        context: context,
        title: context.l10n.errorBoxClearAllSentTitle,
        message: context.l10n.errorBoxClearAllSentMessage(sentIds.length),
        confirmText: context.l10n.errorBoxClearAction,
        onConfirm: () => cubit.deleteErrors(sentIds),
      );
    }
  }

  void _confirmClearAll(BuildContext context) {
    QuanityaConfirmationDialog.show(
      context: context,
      title: context.l10n.errorBoxClearAllTitle,
      message: context.l10n.errorBoxClearAllMessage,
      confirmText: context.l10n.errorBoxClearAll,
      isDestructive: true,
      onConfirm: () {
        final cubit = context.read<ErrorBoxCubit>();
        final ids = cubit.state.unsentErrors.map((e) => e.id).toList();
        cubit.deleteErrors(ids);
      },
    );
  }
}
