import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:get_it/get_it.dart';

import '../../../app_router.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../widgets/error_entry_card.dart';

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
      body: BlocBuilder<ErrorBoxPageCubit, ErrorBoxPageState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.unsentErrors.isEmpty) {
            return _EmptyState();
          }

          return Column(
            children: [
              _PrivacyBanner(),
              Expanded(
                child: ListView.separated(
                  padding: AppPadding.page,
                  itemCount: state.unsentErrors.length,
                  separatorBuilder: (context, index) => VSpace.x3,
                  itemBuilder: (context, index) {
                    final error = state.unsentErrors[index];
                    return ErrorEntryCard(
                      error: error.errorData, // Use errorData from ErrorBoxEntry
                      occurrenceCount: error.occurrenceCount, // Pass occurrence count from ErrorBoxEntry
                      onSend: () => context.read<ErrorBoxPageCubit>().sendError(error.id),
                      onDelete: () => context.read<ErrorBoxPageCubit>().deleteError(error.id),
                    );
                  },
                ),
              ),
              if (state.unsentErrors.isNotEmpty) _SendAllButton(),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: AppSizes.iconLarge * 2,
              color: context.colors.successColor,
            ),
            VSpace.x4,
            Text(
              'No Error Reports',
              style: context.text.headlineMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            VSpace.x2,
            Text(
              'All errors have been reviewed and sent.\nYour privacy is protected.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.allDouble,
      decoration: BoxDecoration(
        color: context.colors.infoColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: context.colors.infoColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: AppSizes.iconMedium,
            color: context.colors.infoColor,
          ),
          HSpace.x2,
          Expanded(
            child: Text(
              'Privacy-first: Only technical error data, no personal information',
              style: context.text.bodySmall?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
