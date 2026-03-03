import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:get_it/get_it.dart';

import '../../logic/analytics/analytics_service.dart';

/// Base Cubit class for Quanitya that extends cubit_ui_flow's TryOperationCubit.
/// 
/// Provides automatic state management with Quanitya-specific integrations
/// and privacy-preserving error capture via ErrorPrivserverMixin.
/// Use this as your base class for all Cubits in the Quanitya application.
abstract class QuanityaCubit<S extends IUiFlowState> extends TryOperationCubit<S> with ErrorPrivserverMixin<S> {
  QuanityaCubit(super.initialState);

  @override
  S createLoadingState() {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.loading,
      error: null,
    ) as S;
  }

  @override
  S createErrorState(Object error) {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.failure,
      error: error,
    ) as S;
  }

  /// Convenience method to create success state
  S createSuccessState() {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.success,
      error: null,
    ) as S;
  }

  /// Convenience method to emit success state
  void emitSuccess() {
    emit(createSuccessState());
  }

  /// Analytics service — null-safe, no-ops if not registered.
  AnalyticsService? get analytics =>
      GetIt.instance.isRegistered<AnalyticsService>()
          ? GetIt.instance<AnalyticsService>()
          : null;
}