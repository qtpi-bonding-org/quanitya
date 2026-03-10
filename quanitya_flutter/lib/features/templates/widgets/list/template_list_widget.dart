import 'package:flutter/material.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../app_router.dart';
import '../../../../design_system/primitives/app_spacings.dart';
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
                      child: SingleChildScrollView(
                        padding: AppPadding.page,
                        child: LayoutGroup.grid(
                          minItemWidth: 20,
                          children: state.templates.map((item) {
                            final cubit = context.read<TemplateListCubit>();
                            return TrackerCard(
                              title: item.template.name,
                              icon: item.aesthetics.icon,
                              emoji: item.aesthetics.emoji,
                              color: item.aesthetics.palette.accents.firstOrNull,
                              template: item.template,
                              onIconTap: () {
                                AppNavigation.toTemplateGenerator(context, item);
                              },
                              onEdit: () {
                                AppNavigation.toLogEntry(context, item.template.id);
                              },
                              onQuickAction: () {
                                cubit.instantLog(item.template);
                              },
                            );
                          }).toList(),
                        ),
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
