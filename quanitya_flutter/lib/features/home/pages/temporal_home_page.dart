import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/bootstrap.dart';
import '../../../app_router.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
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
  
  // Store cubit references to avoid context issues in callbacks
  TemporalTimelineCubit? _timelineCubit;
  TimelineDataCubit? _dataCubit;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1); // Start at Present
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
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
          // Coordinate UI cubit auth state with data cubit
          BlocListener<TemporalTimelineCubit, TemporalTimelineState>(
            listenWhen: (previous, current) => 
              previous.showingHidden != current.showingHidden,
            listener: (context, state) {
              // When auth state changes, update data cubit
              _dataCubit?.setIncludeHidden(state.showingHidden);
            },
          ),
          // Update UI cubit page index when PageView changes
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

              // Layer 1: Page Content
              SafeArea(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _onPageChanged(index);
                    // Update UI cubit with new page index using stored reference
                    _timelineCubit?.setCurrentPage(index);
                  },
                  // Use clamping physics for a solid paper feel
                  physics: const ClampingScrollPhysics(),
                  children: [
                    // Past Panel - Historical log entries
                    TemporalPastPanel(
                      onScrollOffsetChanged: (offset) {
                        setState(() {
                          _pastScrollOffset = offset;
                        });
                      },
                    ),

                    // Present Panel - Template management
                    const TemporalPresentPanel(),

                    // Future Panel - Schedules and reminders
                    TemporalFuturePanel(
                      onScrollOffsetChanged: (offset) {
                        setState(() {
                          _futureScrollOffset = offset;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Layer 2: Settings Button (Top Right) - Always visible
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Filter Buttons - Only for Past page
                      if (_currentIndex == 0)
                        Builder(
                          builder: (context) {
                            final dataState = context.watch<TimelineDataCubit>().state;
                            
                            // Check if filters are active
                            final hasTimeFilter = dataState.filters.timeRange != TimelineTimeRange.all;
                            final hasTemplateFilter = dataState.filters.templateId != null;

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Sort/Time Filter Button
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.sort,
                                    color: hasTimeFilter 
                                        ? palette.textPrimary 
                                        : palette.interactableColor,
                                  ),
                                  tooltip: 'Sort & Time',
                                  color: palette.backgroundPrimary,
                                  surfaceTintColor: palette.backgroundPrimary,
                                  onSelected: (value) async {
                                    if (value == 'toggleDir') {
                                      _dataCubit?.togglePastSort();
                                    } else if (value == 'date') {
                                      _dataCubit?.setPastSort(type: TimelineSortType.date);
                                    } else if (value == 'template') {
                                      _dataCubit?.setPastSort(type: TimelineSortType.template);
                                    } else if (value.startsWith('range_')) {
                                      final rangeName = value.substring(6);
                                      if (rangeName == 'custom') {
                                        final picked = await showDateRangePicker(
                                          context: context,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                          initialDateRange: dataState.filters.customStartDate != null && dataState.filters.customEndDate != null
                                              ? DateTimeRange(start: dataState.filters.customStartDate!, end: dataState.filters.customEndDate!)
                                              : null,
                                        );
                                        if (picked != null) {
                                          _dataCubit?.setTimeRange(TimelineTimeRange.custom, start: picked.start, end: picked.end);
                                        }
                                      } else {
                                        final range = TimelineTimeRange.values.firstWhere(
                                          (e) => e.name == rangeName
                                        );
                                        _dataCubit?.setTimeRange(range);
                                      }
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    // SORT BY
                                    PopupMenuItem(
                                      enabled: false,
                                      child: Text('SORT BY', style: TextStyle(fontSize: AppSizes.fontMini, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                                    ),
                                    PopupMenuItem(
                                      value: 'date',
                                      child: Row(
                                        children: [
                                          Icon(dataState.pastSort.type == TimelineSortType.date ? Icons.check : null, size: AppSizes.iconSmall, color: palette.interactableColor),
                                          HSpace.x1,
                                          const Text('Date'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'template',
                                      child: Row(
                                        children: [
                                          Icon(dataState.pastSort.type == TimelineSortType.template ? Icons.check : null, size: AppSizes.iconSmall, color: palette.interactableColor),
                                          HSpace.x1,
                                          const Text('Template'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    // DIRECTION
                                    PopupMenuItem(
                                      value: 'toggleDir',
                                      child: Row(
                                        children: [
                                          Icon(dataState.pastSort.ascending ? Icons.arrow_upward : Icons.arrow_downward, size: AppSizes.iconSmall, color: palette.interactableColor),
                                          HSpace.x1,
                                          Text(dataState.pastSort.ascending ? 'Oldest First' : 'Newest First'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    // TIME RANGE
                                    PopupMenuItem(
                                      enabled: false,
                                      child: Text('TIME RANGE', style: TextStyle(fontSize: AppSizes.fontMini, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                                    ),
                                    ...TimelineTimeRange.values.map((range) {
                                      String label = range.name.toUpperCase();
                                      if (range == TimelineTimeRange.custom && dataState.filters.customStartDate != null) {
                                        final start = dataState.filters.customStartDate!;
                                        final end = dataState.filters.customEndDate ?? start;
                                        label = '${start.month}/${start.day} - ${end.month}/${end.day}';
                                      }
                                      return PopupMenuItem(
                                        value: 'range_${range.name}',
                                        child: Row(
                                          children: [
                                            Icon(dataState.filters.timeRange == range ? Icons.check : null, size: AppSizes.iconSmall, color: palette.interactableColor),
                                            HSpace.x1,
                                            Text(label),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                
                                // Template Filter Button
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.filter_list,
                                    color: hasTemplateFilter 
                                        ? palette.textPrimary 
                                        : palette.interactableColor,
                                  ),
                                  tooltip: 'Filter by Template',
                                  color: palette.backgroundPrimary,
                                  surfaceTintColor: palette.backgroundPrimary,
                                  onSelected: (value) {
                                    if (value == 'clear') {
                                      _dataCubit?.setTemplateFilter(null);
                                    } else {
                                      _dataCubit?.setTemplateFilter(value);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    PopupMenuItem(
                                      enabled: false,
                                      child: Text('TEMPLATE', style: TextStyle(fontSize: AppSizes.fontMini, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                                    ),
                                    PopupMenuItem(
                                      value: 'clear',
                                      child: Row(
                                        children: [
                                          Icon(dataState.filters.templateId == null ? Icons.check : null, size: AppSizes.iconSmall, color: palette.interactableColor),
                                          HSpace.x1,
                                          const Text('All Templates'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    ...dataState.availableTemplates.map((template) {
                                      return PopupMenuItem(
                                        value: template.id,
                                        child: Row(
                                          children: [
                                            Icon(dataState.filters.templateId == template.id ? Icons.check : null, size: AppSizes.iconSmall, color: palette.interactableColor),
                                            HSpace.x1,
                                            Expanded(
                                              child: Text(
                                                template.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            );
                          }
                        ),
                      // Add Template & Settings Buttons - Only on Present page (index 1)
                      if (_currentIndex == 1) ...[
                        QuanityaIconButton(
                          icon: Icons.assignment_add,
                          iconSize: AppSizes.iconMedium,
                          color: palette.interactableColor,
                          tooltip: context.l10n.createTemplateTitle,
                          onPressed: () => AppNavigation.toTemplateGenerator(context),
                        ),
                        QuanityaIconButton(
                          icon: Icons.notifications_outlined,
                          iconSize: AppSizes.iconMedium,
                          color: palette.interactableColor,
                          tooltip: 'Notifications',
                          onPressed: () => AppNavigation.toNotificationInbox(context),
                        ),
                        QuanityaIconButton(
                          icon: Icons.settings,
                          iconSize: AppSizes.iconMedium,
                          color: palette.interactableColor,
                          tooltip: context.l10n.settingsTitle,
                          onPressed: () => AppNavigation.toSettings(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Layer 3: Navigation Indicator (Bottom)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TemporalIndicator(
                        controller: _pageController,
                        onTabSelected: _onTabSelected,
                      ),
                      VSpace.x1,
                    ],
                  ),
                ),
              ),

              // Layer 4: Lock Icon (top-left) - toggles hidden content visibility
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
                        tooltip: state.showingHidden ? 'Hide private entries' : 'Show private entries',
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
