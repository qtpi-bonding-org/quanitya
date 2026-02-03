import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../app_router.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/widgets/quanitya_empty_or.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../cubits/list/template_list_cubit.dart';
import '../../cubits/list/template_list_state.dart';
import 'dashboard_header.dart';
import 'tracker_card.dart';

class TemplateListWidget extends StatelessWidget {
  const TemplateListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<TemplateListCubit>()..load(),
      child: SafeArea(
          child: Column(
            children: [
              VSpace.x3,
              const DashboardHeader(),
              VSpace.x3,

              Expanded(
                child: BlocConsumer<TemplateListCubit, TemplateListState>(
                  listener: (context, state) {
                    // Show toast feedback for instant log
                    if (state.lastOperation == TemplateListOperation.instantLog) {
                      final feedbackService = GetIt.instance<IFeedbackService>();
                      if (state.isSuccess) {
                        feedbackService.show(
                          FeedbackMessage(
                            message: context.l10n.successGeneric,
                            type: MessageType.success,
                          ),
                        );
                      } else if (state.isFailure) {
                        feedbackService.show(
                          FeedbackMessage(
                            message: state.error?.toString() ?? context.l10n.errorGeneric,
                            type: MessageType.error,
                          ),
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state.isLoading && state.templates.isEmpty) {
                       return const Center(child: CircularProgressIndicator());
                    }
                    
                    return QuanityaEmptyOr(
                      isEmpty: state.templates.isEmpty,
                      child: GridView.builder(
                        padding: AppPadding.page,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSizes.space * 2,
                          mainAxisSpacing: AppSizes.space * 2,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: state.templates.length,
                        itemBuilder: (context, index) {
                          final item = state.templates[index];
                          final cubit = context.read<TemplateListCubit>();
                          return TrackerCard(
                            title: item.template.name,
                            icon: item.aesthetics.icon,
                            emoji: item.aesthetics.emoji,
                            // Use accent1 (first accent color) for the card
                            color: item.aesthetics.palette.accents.firstOrNull,
                            template: item.template, // Pass template for default checking
                            onIconTap: () {
                              // Navigate to template editor
                              AppNavigation.toTemplateGenerator(context, item);
                            },
                            onEdit: () {
                              // Navigate to log entry form (custom log with review)
                              AppNavigation.toLogEntry(context, item.template.id);
                            },
                            onQuickAction: () {
                              // Instant log - save immediately with defaults
                              cubit.instantLog(item.template);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ),
    );
  }
}
