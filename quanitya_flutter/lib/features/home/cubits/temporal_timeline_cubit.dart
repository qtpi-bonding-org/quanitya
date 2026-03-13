import 'package:injectable/injectable.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'temporal_timeline_state.dart';

/// UI-only cubit for temporal home page navigation.
///
/// Tracks which page (Past/Present/Future) is active.
/// Hidden visibility is handled by HiddenVisibilityCubit.
@injectable
class TemporalTimelineCubit extends QuanityaCubit<TemporalTimelineState> {
  TemporalTimelineCubit() : super(const TemporalTimelineState());

  /// Set the current page index for the PageView
  void setCurrentPage(int pageIndex) {
    emit(state.copyWith(currentPageIndex: pageIndex));
  }
}
