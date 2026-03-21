import 'package:flutter/material.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../app/bootstrap.dart';
import '../../../../app_router.dart';
import '../../../guided_tour/guided_tour_service.dart';
import '../../../guided_tour/home_tour.dart';
import '../../../log_entry/widgets/log_entry_sheet.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/widgets/quanitya_empty_or.dart';
import '../../../../support/extensions/context_extensions.dart';
import '../../../hidden_visibility/cubits/hidden_visibility_cubit.dart';
import '../../cubits/list/template_list_cubit.dart';
import '../../cubits/list/template_list_state.dart';
import 'dashboard_header.dart';
import 'tracker_card.dart';

class TemplateListWidget extends StatefulWidget {
  const TemplateListWidget({super.key});

  @override
  State<TemplateListWidget> createState() => _TemplateListWidgetState();
}

class _TemplateListWidgetState extends State<TemplateListWidget> {
  bool _tourAttempted = false;

  Future<void> _maybeShowHomeTour(BuildContext context) async {
    final tourService = getIt<GuidedTourService>();
    if (!await tourService.shouldShowTour(GuidedTourService.homeKey)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (HomeTourKeys.templateCard.currentContext == null) return;

      showHomeTour(
        context,
        temporalLabelsKey: HomeTourKeys.temporalLabels,
        templateCardKey: HomeTourKeys.templateCard,
        quickEntryKey: HomeTourKeys.quickEntry,
        resultsTabKey: HomeTourKeys.resultsTab,
      );
      await tourService.markTourSeen(GuidedTourService.homeKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<TemplateListCubit>()..load(),
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

          // Trigger home tour once templates have loaded
          if (!_tourAttempted &&
              state.templates.isNotEmpty &&
              !state.isLoading) {
            _tourAttempted = true;
            _maybeShowHomeTour(context);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.templates.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter by HiddenVisibilityCubit
          final showHidden = context.watch<HiddenVisibilityCubit>().state.showingHidden;
          final visible = showHidden
              ? state.templates
              : state.templates.where((t) => !t.template.isHidden).toList();

          return QuanityaEmptyOr(
            isEmpty: visible.isEmpty,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: AppSizes.space * 7.5,
                bottom: AppSizes.space * 12.5,
                left: AppSizes.space * 2,
                right: AppSizes.space * 2,
              ),
              child: Column(
                children: [
                  const DashboardHeader(),
                  VSpace.x3,
                  LayoutGroup.grid(
                    minItemWidth: 20,
                    children: [
                      for (var i = 0; i < visible.length; i++)
                        () {
                          final item = visible[i];
                          final cubit = context.read<TemplateListCubit>();
                          return TrackerCard(
                            title: item.template.name,
                            icon: item.aesthetics.icon,
                            emoji: item.aesthetics.emoji,
                            color: item.aesthetics.palette.accents.firstOrNull,
                            template: item.template,
                            tourCardKey: i == 0 ? HomeTourKeys.templateCard : null,
                            tourQuickEntryKey: i == 0 ? HomeTourKeys.quickEntry : null,
                            onIconTap: () {
                              AppNavigation.toTemplateDesigner(context, item);
                            },
                            onEdit: () {
                              LogEntrySheet.showCreate(
                                context: context,
                                templateId: item.template.id,
                              );
                            },
                            onQuickAction: () {
                              cubit.instantLog(item.template);
                            },
                          );
                        }(),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
