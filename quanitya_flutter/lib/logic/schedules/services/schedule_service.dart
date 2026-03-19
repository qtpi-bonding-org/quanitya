import 'package:injectable/injectable.dart';

import '../../../data/repositories/schedule_repository.dart';
import '../models/schedule.dart';
import 'schedule_generator_service.dart';

/// Facade for schedule lifecycle operations.
///
/// Coordinates between [ScheduleRepository] (persistence) and
/// [ScheduleGeneratorService] (todos + notifications) so cubits
/// only call a single method per action.
@lazySingleton
class ScheduleService {
  final ScheduleRepository _repo;
  final ScheduleGeneratorService _generator;

  ScheduleService(this._repo, this._generator);

  /// Save a schedule and generate todos + notifications for it.
  Future<void> save(ScheduleModel schedule) async {
    await _repo.save(schedule);
    await _generator.generateForSchedule(schedule.id);
  }

  /// Delete a schedule and clean up its todos + notifications.
  Future<void> delete(String scheduleId) async {
    final schedule = await _repo.getSchedule(scheduleId);
    if (schedule != null) {
      await _generator.cancelForSchedule(schedule.templateId);
    }
    await _repo.delete(scheduleId);
  }
}
