import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../infrastructure/platform/platform_local_auth.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'hidden_visibility_state.dart';

/// App-wide cubit controlling visibility of hidden templates and entries.
///
/// Single source of truth for the "lock" toggle. Owns authentication —
/// consumers (TimelineDataCubit, ScheduleListCubit, TemplateListCubit)
/// receive the state via the widget tree and call their own setters.
@lazySingleton
class HiddenVisibilityCubit extends QuanityaCubit<HiddenVisibilityState> {
  final PlatformLocalAuth _localAuthService;
  final ILocalizationService _l10nService;

  HiddenVisibilityCubit(
    this._localAuthService,
    this._l10nService,
  ) : super(const HiddenVisibilityState());

  /// Toggle visibility of hidden entries (requires local auth to unlock).
  Future<void> toggleShowHidden() async {
    if (state.showingHidden) {
      // Locking doesn't require auth
      emit(state.copyWith(showingHidden: false));
      return;
    }

    // Unlocking requires authentication
    final result = await _localAuthService.authenticate(
      reason: _l10nService.translate('authenticate.view.hidden'),
    );

    if (result) {
      emit(state.copyWith(
        showingHidden: true,
        status: UiFlowStatus.success,
        lastOperation: HiddenVisibilityOperation.toggleHidden,
      ));
    }
    // If auth failed/cancelled, do nothing — stay locked
  }
}
