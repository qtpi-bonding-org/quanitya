import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../logic/analytics/analytics_service.dart';
import '../../../data/repositories/analytics_inbox_repository.dart';
import '../../../features/app_syncing_mode/repositories/app_syncing_repository.dart';
import 'analytics_state.dart';

@lazySingleton
class AnalyticsCubit extends QuanityaCubit<AnalyticsState> {
  final AnalyticsInboxRepository _inboxRepo;
  final AnalyticsService _analyticsService;
  final AppSyncingRepository _settingsRepo;

  StreamSubscription<List>? _groupedSub;
  StreamSubscription<int>? _countSub;

  AnalyticsCubit(
    this._inboxRepo,
    this._analyticsService,
    this._settingsRepo,
  ) : super(const AnalyticsState());

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

  /// Send all unsent events to the server.
  ///
  /// Does NOT auto-clear sent events — the UI should prompt the user
  /// to clear after a successful send.
  Future<void> sendAll() async {
    await tryOperation(() async {
      final sentCount = await _analyticsService.sendAllUnsent();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: AnalyticsOperation.sendAll,
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
        lastOperation: AnalyticsOperation.clearSent,
      );
    });
  }

  /// Clear all events (sent and unsent)
  Future<void> clearAll() async {
    await tryOperation(() async {
      await _inboxRepo.clearAllEvents();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: AnalyticsOperation.clearAll,
      );
    });
  }

  /// Toggle auto-send preference
  Future<void> toggleAutoSend(bool enabled) async {
    await tryOperation(() async {
      await _settingsRepo.updateAnalyticsAutoSend(enabled);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: AnalyticsOperation.toggleAutoSend,
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
