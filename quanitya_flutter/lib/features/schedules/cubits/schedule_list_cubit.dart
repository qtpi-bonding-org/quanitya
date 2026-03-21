import 'dart:async';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../logic/schedules/models/schedule.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../logic/schedules/services/schedule_service.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'schedule_list_state.dart';

/// Cubit for managing the schedule list on the Future page.
///
/// Watches all active schedules and enriches them with template context.
/// Always loads all schedules (including hidden). UI filters visibility
/// based on HiddenVisibilityCubit.
@injectable
class ScheduleListCubit extends QuanityaCubit<ScheduleListState> {
  final ScheduleRepository _scheduleRepository;
  final TemplateWithAestheticsRepository _templateRepository;
  final ScheduleService _scheduleService;
  StreamSubscription? _subscription;

  ScheduleListCubit(
    this._scheduleRepository,
    this._templateRepository,
    this._scheduleService,
  ) : super(const ScheduleListState());

  /// Start watching schedules
  void load() {
    _subscription?.cancel();
    _subscription = _scheduleRepository.watchAllSchedules().listen(
      (schedules) async {
        // Enrich schedules with template context
        final enriched = <ScheduleWithContext>[];
        for (final schedule in schedules) {
          final templateWithAesthetics = await _templateRepository.findById(schedule.templateId);
          if (templateWithAesthetics != null) {
            enriched.add(ScheduleWithContext(
              schedule: schedule,
              template: templateWithAesthetics.template,
              aesthetics: templateWithAesthetics.aesthetics,
            ));
          }
        }
        emit(state.copyWith(
          schedules: enriched,
          status: UiFlowStatus.success,
          lastOperation: ScheduleListOperation.load,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: UiFlowStatus.failure,
          error: e,
        ));
      },
    );
  }

  /// Pause a schedule (set isActive = false)
  Future<void> pause(String scheduleId) async {
    await tryOperation(() async {
      await _scheduleRepository.pause(scheduleId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ScheduleListOperation.pause,
      );
    }, emitLoading: false); // Quick action, no loading overlay
  }

  /// Resume a schedule (set isActive = true)
  Future<void> resume(String scheduleId) async {
    await tryOperation(() async {
      await _scheduleRepository.resume(scheduleId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ScheduleListOperation.resume,
      );
    }, emitLoading: false);
  }

  /// Create a new schedule and generate its todos + notifications
  Future<void> create(ScheduleModel schedule) async {
    await tryOperation(() async {
      await _scheduleService.save(schedule);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ScheduleListOperation.create,
      );
    }, emitLoading: true);
  }

  /// Delete a schedule and clean up its notifications + todos
  Future<void> delete(String scheduleId) async {
    await tryOperation(() async {
      await _scheduleService.delete(scheduleId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ScheduleListOperation.delete,
      );
    }, emitLoading: true);
  }

  /// Update a schedule
  Future<void> update(ScheduleModel schedule) async {
    await tryOperation(() async {
      await _scheduleRepository.save(schedule);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: ScheduleListOperation.update,
      );
    }, emitLoading: false); // No loading overlay for seamless updates
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
