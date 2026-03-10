import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:get_it/get_it.dart';

import '../../../app_router.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
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
      create: (_) => GetIt.instance<ErrorBoxPageCubit>()..loadErrors(),
      child: const _ErrorBoxView(),
    );
  }
}

class _ErrorBoxView extends StatelessWidget {
  const _ErrorBoxView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Error Reports',
          style: context.text.headlineMedium,
        ),
        leading: QuanityaIconButton(
          icon: Icons.arrow_back,
          onPressed: () => AppNavigation.back(context),
        ),
      ),
      body: const ErrorsTabContent(),
    );
  }
}

/// Reusable error reports content — used in both standalone ErrorBoxPage
/// and the unified OutboxPage tab.
class ErrorsTabContent extends StatelessWidget {
  const ErrorsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ErrorBoxPageCubit, ErrorBoxPageState>(
      builder: (context, state) {
        return OutboxTabContent(
          isLoading: state.isLoading,
          isEmpty: state.unsentErrors.isEmpty,
          emptyState: OutboxEmptyState(
            icon: Icons.check_circle_outline,
            iconColor: context.colors.successColor,
            title: 'No Error Reports',
            description: 'All errors have been reviewed and sent.\nYour privacy is protected.',
          ),
          banner: OutboxPrivacyBanner(
            text: 'Privacy-first: Only technical error data, no personal information',
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
                onSend: () => context.read<ErrorBoxPageCubit>().sendError(error.id),
                onDelete: () => context.read<ErrorBoxPageCubit>().deleteError(error.id),
              );
            },
          ),
          bottomAction: _SendAllButton(),
        );
      },
    );
  }
}

class _SendAllButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          text: 'Send All Reports',
          onPressed: () => context.read<ErrorBoxPageCubit>().sendAllErrors(),
        ),
      ),
    );
  }
}
