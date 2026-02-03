import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../../../infrastructure/platform/platform_local_auth.dart';
import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import 'temporal_timeline_state.dart';

@injectable
class TemporalTimelineCubit extends QuanityaCubit<TemporalTimelineState> {
  final PlatformLocalAuth _localAuthService;

  TemporalTimelineCubit(
    this._localAuthService,
  ) : super(const TemporalTimelineState());

  // ─────────────────────────────────────────────────────────────────────────
  // UI Actions - Authentication & Navigation Only
  // ─────────────────────────────────────────────────────────────────────────

  /// Toggle visibility of hidden entries (requires local auth to unlock).
  /// UI should call TimelineDataCubit.setIncludeHidden() after successful auth.
  Future<void> toggleShowHidden() async {
    if (state.showingHidden) {
      // Locking doesn't require auth
      emit(state.copyWith(showingHidden: false));
      return;
    }

    // Unlocking requires authentication
    final result = await _localAuthService.authenticate(
      reason: 'Authenticate to view hidden entries',
    );

    if (result) {
      emit(state.copyWith(
        showingHidden: true,
        status: UiFlowStatus.success,
        lastOperation: TemporalTimelineOperation.toggleHidden,
      ));
    }
    // If auth failed/cancelled, do nothing - stay locked
  }

  /// Set the current page index for the PageView
  void setCurrentPage(int pageIndex) {
    emit(state.copyWith(currentPageIndex: pageIndex));
  }
}
