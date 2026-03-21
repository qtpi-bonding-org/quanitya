import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/bootstrap.dart';
import '../../../app_router.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../guided_tour/guided_tour_service.dart';
import '../../../design_system/primitives/quanitya_fonts.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/swipeable_page_shell.dart';
import '../../../dev/dev_module.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../hidden_visibility/cubits/hidden_visibility_cubit.dart';
import '../../schedules/cubits/schedule_list_cubit.dart';
import '../../schedules/widgets/add_schedule_sheet.dart';
import '../cubits/temporal_timeline_cubit.dart';
import '../cubits/temporal_timeline_state.dart';
import '../cubits/timeline_data_cubit.dart';
import '../cubits/timeline_data_state.dart';
import '../widgets/temporal_past_panel.dart';
import '../widgets/temporal_present_panel.dart';
import '../widgets/temporal_future_panel.dart';
import '../widgets/sort_options_sheet.dart';
import '../widgets/template_filter_sheet.dart';

class TemporalHomePage extends StatefulWidget {
  const TemporalHomePage({super.key});

  @override
  State<TemporalHomePage> createState() => _TemporalHomePageState();
}

class _TemporalHomePageState extends State<TemporalHomePage> {
  late final PageController _pageController;
  int _currentIndex = 1;

  TemporalTimelineCubit? _timelineCubit;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addSchedule(BuildContext context) async {
    final cubit = context.read<ScheduleListCubit>();
    final scheduledIds = cubit.state.schedules
        .map((s) => s.schedule.templateId)
        .toSet();

    final schedule = await AddScheduleSheet.show(
      context,
      scheduledTemplateIds: scheduledIds,
    );

    if (schedule != null && context.mounted) {
      cubit.create(schedule);
    }
  }

  Widget _buildTemporalLabel(BuildContext context, String text) {
    final palette = QuanityaPalette.primary;
    final labels = ['-t', 't', '+t'];
    final index = labels.indexOf(text);
    final isActive = _currentIndex == index;

    return Text(
      text,
      style: context.text.bodyLarge?.copyWith(
        fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
        color: isActive ? palette.textPrimary : palette.interactableColor,
        fontFamily: QuanityaFonts.headerFamily,
        fontSize: AppSizes.fontLarge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            _timelineCubit = getIt.get<TemporalTimelineCubit>();
            return _timelineCubit!;
          },
        ),
        BlocProvider(
          create: (context) => getIt.get<TimelineDataCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt.get<ScheduleListCubit>()..load(),
        ),
      ],
      child: BlocListener<TemporalTimelineCubit, TemporalTimelineState>(
        listenWhen: (previous, current) =>
          previous.currentPageIndex != current.currentPageIndex,
        listener: (context, state) {
          if (state.currentPageIndex != _currentIndex) {
            _pageController.animateToPage(
              state.currentPageIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: SwipeablePageShell(
            controller: _pageController,
            initialPage: 1,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _timelineCubit?.setCurrentPage(index);
            },
            pages: const [
              TemporalPastPanel(),
              TemporalPresentPanel(),
              TemporalFuturePanel(),
            ],
            labels: [
              _buildTemporalLabel(context, '-t'),
              KeyedSubtree(
                key: HomeTourKeys.temporalLabels,
                child: _buildTemporalLabel(context, 't'),
              ),
              _buildTemporalLabel(context, '+t'),
            ],
            semanticTabLabels: [
              context.l10n.homePastDescription,
              context.l10n.homePresentDescription,
              context.l10n.homeFutureDescription,
            ],
            overlays: [
              // Action Buttons (Top Right) - contextual per page
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentIndex == 0)
                        Builder(
                          builder: (context) {
                            final dataState = context.watch<TimelineDataCubit>().state;
                            final hasTimeFilter = dataState.filters.timeRange != TimelineTimeRange.all;
                            final hasTemplateFilter = dataState.filters.templateId != null;

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                QuanityaIconButton(
                                  icon: Icons.sort,
                                  color: hasTimeFilter
                                      ? palette.textPrimary
                                      : palette.interactableColor,
                                  tooltip: context.l10n.tooltipSortAndTime,
                                  onPressed: () => SortOptionsSheet.show(
                                    context,
                                    context.read<TimelineDataCubit>(),
                                  ),
                                ),
                                QuanityaIconButton(
                                  icon: Icons.filter_list,
                                  color: hasTemplateFilter
                                      ? palette.textPrimary
                                      : palette.interactableColor,
                                  tooltip: context.l10n.tooltipFilterByTemplate,
                                  onPressed: () => TemplateFilterSheet.show(
                                    context,
                                    context.read<TimelineDataCubit>(),
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                      if (_currentIndex == 1)
                        QuanityaIconButton(
                          icon: Icons.assignment_add,
                          iconSize: AppSizes.iconMedium,
                          color: palette.interactableColor,
                          tooltip: context.l10n.createTemplateTitle,
                          onPressed: () => AppNavigation.toTemplateDesigner(context),
                        ),
                      if (_currentIndex == 2)
                        QuanityaIconButton(
                          icon: Icons.alarm_add,
                          iconSize: AppSizes.iconMedium,
                          color: palette.interactableColor,
                          tooltip: context.l10n.addSchedule,
                          onPressed: () => _addSchedule(context),
                        ),
                    ],
                  ),
                ),
              ),

              // Lock Icon (top-left) — driven by HiddenVisibilityCubit
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Builder(
                    builder: (context) {
                      final state = context.watch<HiddenVisibilityCubit>().state;

                      return QuanityaIconButton(
                        icon: state.showingHidden ? Icons.lock_open : Icons.lock,
                        iconSize: AppSizes.iconMedium,
                        color: palette.interactableColor,
                        tooltip: state.showingHidden ? context.l10n.tooltipHidePrivate : context.l10n.tooltipShowPrivate,
                        onPressed: () => context.read<HiddenVisibilityCubit>().toggleShowHidden(),
                      );
                    },
                  ),
                ),
              ),

              if (kDebugMode)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: SafeArea(child: DevFab()),
                ),
            ],
          ),
      ),
    );
  }
}
