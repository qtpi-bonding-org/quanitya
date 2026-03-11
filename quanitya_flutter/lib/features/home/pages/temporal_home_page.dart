import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/bootstrap.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_fonts.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/swipeable_page_shell.dart';
import '../../../dev/dev_module.dart';
import '../../../infrastructure/notifications/notification_service.dart';
import '../../../integrations/flutter/health/health_sync_service.dart';
import 'package:health/health.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/temporal_timeline_cubit.dart';
import '../cubits/temporal_timeline_state.dart';
import '../cubits/timeline_data_cubit.dart';
import '../cubits/timeline_data_state.dart';
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
    _requestPermissions();
  }

  void _requestPermissions() {
    if (getIt.isRegistered<NotificationService>()) {
      getIt<NotificationService>().requestPermissions();
    }
    if (getIt.isRegistered<HealthSyncService>()) {
      getIt<HealthSyncService>().requestPermissions([
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.BODY_TEMPERATURE,
        HealthDataType.WEIGHT,
      ]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        child: SwipeablePageShell(
            controller: _pageController,
            initialPage: 1,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _timelineCubit?.setCurrentPage(index);
            },
            scrollOffsets: [_pastScrollOffset, 0.0, _futureScrollOffset],
            pages: [
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
            labels: [
              _buildTemporalLabel(context, '-t'),
              _buildTemporalLabel(context, 't'),
              _buildTemporalLabel(context, '+t'),
            ],
            overlays: [
              // Filter Buttons (Top Right) - Past page only
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

              // Lock Icon (top-left)
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
