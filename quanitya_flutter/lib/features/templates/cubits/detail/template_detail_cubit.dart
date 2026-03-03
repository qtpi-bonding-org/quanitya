import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../../data/interfaces/log_entry_interface.dart';
import '../../../../data/repositories/schedule_repository.dart';
import '../../../../logic/schedules/models/schedule.dart';
import 'template_detail_state.dart';

@injectable
class TemplateDetailCubit extends QuanityaCubit<TemplateDetailState> {
  final TemplateWithAestheticsRepository _templateRepo;
  final ILogEntryRepository _logEntryRepo;
  final ScheduleRepository _scheduleRepo;

  StreamSubscription? _templateSub;
  StreamSubscription? _logSub;
  StreamSubscription? _scheduleSub;

  TemplateDetailCubit(
    this._templateRepo,
    this._logEntryRepo,
    this._scheduleRepo,
  ) : super(const TemplateDetailState());

  Future<void> load(String templateId) async {
    await tryOperation(() async {
       await _templateSub?.cancel();
       await _logSub?.cancel();
       await _scheduleSub?.cancel();

       _templateSub = _templateRepo.watchById(templateId).listen((data) {
          emit(state.copyWith(template: data));
       });

       _logSub = _logEntryRepo.watchEntriesForTemplate(templateId).listen((entries) {
          final recent = entries.take(5).toList();
          emit(state.copyWith(recentEntries: recent));
       }, onError: (e) {
         // ignore error or handle
       });

       _scheduleSub = _scheduleRepo.watchSchedulesForTemplate(templateId).listen((schedules) {
          emit(state.copyWith(schedules: schedules));
       }, onError: (e) {
          // ignore error which might happen if unimplemented
       });

       return state.copyWith(
         status: UiFlowStatus.success,
         lastOperation: TemplateDetailOperation.load,
       );
    }, emitLoading: true);
  }

  Future<void> saveSchedule(ScheduleModel schedule) async {
    await _scheduleRepo.save(schedule);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _scheduleRepo.delete(scheduleId);
  }

  @override
  Future<void> close() {
    _templateSub?.cancel();
    _logSub?.cancel();
    _scheduleSub?.cancel();
    return super.close();
  }
}
