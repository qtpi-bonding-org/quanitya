import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/bootstrap.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../dev/dev_module.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/temporal_timeline_cubit.dart';
import '../cubits/temporal_timeline_state.dart';
import '../cubits/timeline_data_cubit.dart';
import '../cubits/timeline_data_state.dart';
import '../widgets/temporal_indicator.dart';
import '../widgets/temporal_zen_paper.dart';
import '../widgets/temporal_past_panel.dart';
import '../widgets/temporal_present_panel.dart';
import '../widgets/temporal_future_panel.dart';
import '../widgets/sort_options_sheet.dart';
import '../widgets/template_filter_sheet.dart';
import '../../schedules/cubits/schedule_list_cubit.dart';

class TemporalHomePage extends StatefulWidget {
  const TemporalHomePage({super.key});

  @override
  State<TemporalHomePage> createState() => _TemporalHomePageState();
}

class _TemporalHomePageState extends State<TemporalHomePage> {
  late final PageController _pageController;
  int _currentIndex = 1;
  double _pastScrollOffset = 0.0;
  double _futureScrollOffset = 0.0;

  TemporalTimelineCubit? _timelineCubit;
  TimelineDataCubit? _dataCubit;

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
          create: (context) {
            _dataCubit = getIt.get<TimelineDataCubit>();
            return _dataCubit!;
          },
        ),
        BlocProvider(
          create: (context) => getIt.get<ScheduleListCubit>()..load(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<TemporalTimelineCubit, TemporalTimelineState>(
            listenWhen: (previous, current) =>
              previous.showingHidden != current.showingHidden,
            listener: (context, state) {
              _dataCubit?.setIncludeHidden(state.showingHidden);
            },
          ),
          BlocListener<TemporalTimelineCubit, TemporalTimelineState>(
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
          ),
        ],
        child: Scaffold(
          backgroundColor: palette.backgroundPrimary,
          floatingActionButton: const DevFab(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Stack(
            children: [
              // Layer 0: Washi Paper Background
              TemporalZenPaper(
                controller: _pageController,
                pastScrollOffset: _pastScrollOffset,
                futureScrollOffset: _futureScrollOffset,
              ),

              // Layer 1: Content + Indicator in a Column
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentIndex = index);
                          _timelineCubit?.setCurrentPage(index);
                        },
                        physics: const ClampingScrollPhysics(),
                        children: [
                          TemporalPastPanel(
                            onScrollOffsetChanged: (offset) {
                              setState(() => _pastScrollOffset = offset);
                            },
                          ),
                          const TemporalPresentPanel(),
                          TemporalFuturePanel(
                            onScrollOffsetChanged: (offset) {
                              setState(() => _futureScrollOffset = offset);
                            },
                          ),
                        ],
                      ),
                    ),
                    // Indicator sits at bottom, in the layout flow
                    TemporalIndicator(
                      controller: _pageController,
                      onTabSelected: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Layer 2: Filter Buttons (Top Right) - Past page only
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
                                    _dataCubit!,
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
                                    _dataCubit!,
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                    ],
                  ),
                ),
              ),

              // Layer 3: Lock Icon (top-left)
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Builder(
                    builder: (context) {
                      final state = context.watch<TemporalTimelineCubit>().state;

                      return QuanityaIconButton(
                        icon: state.showingHidden ? Icons.lock_open : Icons.lock,
                        iconSize: AppSizes.iconMedium,
                        color: palette.interactableColor,
                        tooltip: state.showingHidden ? context.l10n.tooltipHidePrivate : context.l10n.tooltipShowPrivate,
                        onPressed: () => _timelineCubit?.toggleShowHidden(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
