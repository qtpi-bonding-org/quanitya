import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../logic/analytics/analytics_service.dart';
import '../../../data/repositories/analytics_inbox_repository.dart';
import '../../../features/app_operating_mode/repositories/app_operating_repository.dart';
import 'analytics_inbox_state.dart';

@injectable
class AnalyticsInboxCubit extends QuanityaCubit<AnalyticsInboxState> {
  final AnalyticsInboxRepository _inboxRepo;
  final AnalyticsService _analyticsService;
  final AppOperatingRepository _settingsRepo;

  StreamSubscription<List>? _groupedSub;
  StreamSubscription<int>? _countSub;

  AnalyticsInboxCubit(
    this._inboxRepo,
    this._analyticsService,
    this._settingsRepo,
  ) : super(const AnalyticsInboxState());

  /// Initialize: load auto-send preference and start watching events
  Future<void> load() async {
    final autoSend = await _settingsRepo.getAnalyticsAutoSend();
    emit(state.copyWith(autoSendEnabled: autoSend));

    _groupedSub = _inboxRepo.watchGroupedUnsent().listen((grouped) {
      emit(state.copyWith(groupedEvents: grouped));
    });

    _countSub = _inboxRepo.watchUnsentCount().listen((count) {
      emit(state.copyWith(unsentCount: count));
    });
  }

  /// Send all unsent events to the server
  Future<void> sendAll() async {
    await tryOperation(() async {
      final sentCount = await _analyticsService.sendAllUnsent();
      // Clean up sent events from local storage
      await _inboxRepo.clearSentEvents();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: AnalyticsInboxOperation.sendAll,
        lastSentCount: sentCount,
      );
    }, emitLoading: true);
  }

  /// Clear all sent events
  Future<void> clearSent() async {
    await tryOperation(() async {
      await _inboxRepo.clearSentEvents();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: AnalyticsInboxOperation.clearSent,
      );
    });
  }

  /// Clear all events (sent and unsent)
  Future<void> clearAll() async {
    await tryOperation(() async {
      await _inboxRepo.clearAllEvents();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: AnalyticsInboxOperation.clearAll,
      );
    });
  }

  /// Toggle auto-send preference
  Future<void> toggleAutoSend(bool enabled) async {
    await tryOperation(() async {
      await _settingsRepo.updateAnalyticsAutoSend(enabled);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: AnalyticsInboxOperation.toggleAutoSend,
        autoSendEnabled: enabled,
      );
    });
  }

  @override
  Future<void> close() {
    _groupedSub?.cancel();
    _countSub?.cancel();
    return super.close();
  }
}
