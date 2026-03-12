import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../app_router.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_confirmation_dialog.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../cubits/error_box_cubit.dart';
import '../cubits/error_box_state.dart';
import '../cubits/error_box_message_mapper.dart';
import '../widgets/error_entry_card.dart';
import '../../outbox/widgets/outbox_tab_content.dart';

/// Error Box Page - Review and send privacy-preserving error reports
///
/// Shows all unsent errors captured by ErrorPrivserver with complete
/// transparency about what data will be sent to developers.
class ErrorBoxPage extends StatelessWidget {
  const ErrorBoxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<ErrorBoxCubit>()..load(),
      child: const _ErrorBoxView(),
    );
  }
}

class _ErrorBoxView extends StatelessWidget {
  const _ErrorBoxView();

  @override
  Widget build(BuildContext context) {
    return UiFlowListener<ErrorBoxCubit, ErrorBoxState>(
      mapper: GetIt.instance<ErrorBoxMessageMapper>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n.settingsErrorReports,
            style: context.text.headlineMedium,
          ),
          leading: QuanityaIconButton(
            icon: Icons.arrow_back,
            onPressed: () => AppNavigation.back(context),
          ),
        ),
        body: const ErrorsTabContent(),
      ),
    );
  }
}

/// Reusable error reports content — used in both standalone ErrorBoxPage
/// and the unified PostagePage tab.
class ErrorsTabContent extends StatelessWidget {
  const ErrorsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ErrorBoxCubit, ErrorBoxState>(
      builder: (context, state) {
        return OutboxTabContent(
          isLoading: state.status == UiFlowStatus.loading,
          isEmpty: state.unsentErrors.isEmpty,
          emptyState: OutboxEmptyState(
            icon: Icons.bug_report_outlined,
            title: context.l10n.errorBoxNoReports,
            description: context.l10n.errorBoxNoReportsDescription,
          ),
          banner: OutboxPrivacyBanner(
            text: context.l10n.errorBoxPrivacyBanner,
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

class _BottomActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ErrorBoxCubit, ErrorBoxState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: AppPadding.allDouble,
          decoration: BoxDecoration(
            color: context.colors.backgroundPrimary,
            border: Border(
              top: BorderSide(
                color: context.colors.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: QuanityaTextButton(
              text: context.l10n.errorBoxSendAllReports,
              onPressed: state.status == UiFlowStatus.loading
                  ? null
                  : () => _sendAllAndPromptClear(context),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendAllAndPromptClear(BuildContext context) async {
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
}
