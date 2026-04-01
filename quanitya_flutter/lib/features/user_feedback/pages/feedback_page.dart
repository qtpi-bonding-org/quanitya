import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../l10n/app_localizations.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/pen_circled_chip.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../account/widgets/account_id_display.dart';
import '../../postage/widgets/postage_tab_content.dart';
import '../cubits/feedback_cubit.dart';
import '../cubits/feedback_state.dart';

/// Feedback form content — embedded in [NotebookShell] via PostagePage.
class FeedbackTabContent extends StatefulWidget {
  const FeedbackTabContent({super.key});

  @override
  State<FeedbackTabContent> createState() => _FeedbackTabContentState();
}

class _FeedbackTabContentState extends State<FeedbackTabContent> {
  final _textController = TextEditingController();
  String _selectedType = 'general';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<FeedbackCubit, FeedbackState>(
      builder: (context, state) {
        return PostageTabContent(
          content: Center(
            child: SingleChildScrollView(
              padding: AppPadding.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AccountIdDisplay(),
                VSpace.x3,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PenCircledChip(
                      icon: Icons.lightbulb_outline,
                      label: l10n.feedbackTypeFeature,
                      isSelected: _selectedType == 'feature_request',
                      onTap: () => setState(() => _selectedType = 'feature_request'),
                    ),
                    HSpace.x3,
                    PenCircledChip(
                      icon: Icons.bug_report,
                      label: l10n.feedbackTypeBug,
                      isSelected: _selectedType == 'bug',
                      onTap: () => setState(() => _selectedType = 'bug'),
                    ),
                    HSpace.x3,
                    PenCircledChip(
                      icon: Icons.chat_bubble_outline,
                      label: l10n.feedbackTypeGeneral,
                      isSelected: _selectedType == 'general',
                      onTap: () => setState(() => _selectedType = 'general'),
                    ),
                  ],
                ),
                VSpace.x4,
                QuanityaTextField(
                  controller: _textController,
                  maxLines: 10,
                  hintText: l10n.feedbackHint,
                ),
                VSpace.x3,
                Text(
                  l10n.feedbackPrivacyNotice,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                VSpace.x4,
                QuanityaTextButton(
                  text: l10n.feedbackSubmitButton,
                  onPressed: state.status == UiFlowStatus.loading
                      ? null
                      : () => _submitFeedback(context),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  void _submitFeedback(BuildContext context) {
    final text = _textController.text.trim();
    if (text.length < 10) {
      final l10n = AppLocalizations.of(context)!;
      context.read<IFeedbackService>().show(FeedbackMessage(
          message: l10n.errorFeedbackTooShort,
          type: MessageType.warning));
      return;
    }
    context.read<FeedbackCubit>().submitFeedback(
      feedbackText: text,
      feedbackType: _selectedType,
    );
  }
}

