import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../cubits/feedback_cubit.dart';
import '../cubits/feedback_state.dart';
import '../mappers/feedback_message_mapper.dart';

/// Page for submitting user feedback.
class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<FeedbackCubit>(),
      child: const _FeedbackPageContent(),
    );
  }
}

class _FeedbackPageContent extends StatefulWidget {
  const _FeedbackPageContent();
  
  @override
  State<_FeedbackPageContent> createState() => _FeedbackPageContentState();
}

class _FeedbackPageContentState extends State<_FeedbackPageContent> {
  final _textController = TextEditingController();
  String _selectedType = 'general';
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return UiFlowListener<FeedbackCubit, FeedbackState>(
      mapper: GetIt.instance<FeedbackMessageMapper>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Send Feedback',
            style: context.text.headlineMedium,
          ),
          leading: QuanityaIconButton(
            icon: Icons.arrow_back,
            onPressed: () => AppNavigation.back(context),
          ),
        ),
        body: BlocBuilder<FeedbackCubit, FeedbackState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: AppPadding.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type selector
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'feature_request',
                        label: Text('Feature'),
                        icon: Icon(Icons.lightbulb_outline),
                      ),
                      ButtonSegment(
                        value: 'bug',
                        label: Text('Bug'),
                        icon: Icon(Icons.bug_report),
                      ),
                      ButtonSegment(
                        value: 'general',
                        label: Text('General'),
                        icon: Icon(Icons.chat_bubble_outline),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() => _selectedType = selected.first);
                    },
                  ),
                  
                  VSpace.x4,
                  
                  // Text input
                  QuanityaTextField(
                    controller: _textController,
                    maxLines: 10,
                    hintText: 'Tell us what you think...',
                  ),
                  
                  VSpace.x3,
                  
                  // Privacy notice
                  Container(
                    padding: AppPadding.allDouble,
                    decoration: BoxDecoration(
                      color: QuanityaPalette.primary.backgroundPrimary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Row(
                        children: [
                          Icon(
                            Icons.privacy_tip_outlined,
                            size: AppSizes.iconMedium,
                            color: context.colors.interactableColor,
                          ),
                          HSpace.x2,
                          Expanded(
                            child: Text(
                              'Your feedback is anonymous and helps us improve.',
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.textPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  VSpace.x4,
                  
                  // Submit button
                  QuanityaTextButton(
                    text: 'Submit Feedback',
                    onPressed: state.status == UiFlowStatus.loading
                        ? null
                        : () => _submitFeedback(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  void _submitFeedback(BuildContext context) {
    final text = _textController.text.trim();
    
    if (text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback must be at least 10 characters'),
        ),
      );
      return;
    }
    
    context.read<FeedbackCubit>().submitFeedback(
      feedbackText: text,
      feedbackType: _selectedType,
    );
  }
}
