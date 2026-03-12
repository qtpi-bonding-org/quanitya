import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../l10n/app_localizations.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/post_it_toast.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../outbox/widgets/outbox_tab_content.dart';
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
        return OutboxTabContent(
          content: Center(
            child: SingleChildScrollView(
              padding: AppPadding.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FeedbackTypeChip(
                      value: 'feature_request',
                      icon: Icons.lightbulb_outline,
                      label: l10n.feedbackTypeFeature,
                      isSelected: _selectedType == 'feature_request',
                      onTap: () => setState(() => _selectedType = 'feature_request'),
                    ),
                    HSpace.x3,
                    _FeedbackTypeChip(
                      value: 'bug',
                      icon: Icons.bug_report,
                      label: l10n.feedbackTypeBug,
                      isSelected: _selectedType == 'bug',
                      onTap: () => setState(() => _selectedType = 'bug'),
                    ),
                    HSpace.x3,
                    _FeedbackTypeChip(
                      value: 'general',
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
      PostItToast.show(context,
          message: l10n.errorFeedbackTooShort,
          type: PostItType.warning);
      return;
    }
    context.read<FeedbackCubit>().submitFeedback(
      feedbackText: text,
      feedbackType: _selectedType,
    );
  }
}

class _FeedbackTypeChip extends StatelessWidget {
  final String value;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeedbackTypeChip({
    required this.value,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? context.colors.textPrimary
        : context.colors.interactableColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.space * 2,
          vertical: AppSizes.space,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.textPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(
            color: isSelected
                ? context.colors.textPrimary
                : context.colors.interactableColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppSizes.iconLarge),
            if (isSelected) ...[
              VSpace.x1,
              Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
