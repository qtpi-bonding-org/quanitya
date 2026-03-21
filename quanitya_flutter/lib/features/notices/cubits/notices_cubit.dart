import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../data/repositories/notification_repository.dart';
import '../../../data/db/app_database.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';

part 'notices_cubit.freezed.dart';

@injectable
class NoticesCubit extends QuanityaCubit<NoticesState> {
  final NotificationRepository _repository;
  StreamSubscription? _subscription;

  NoticesCubit(this._repository)
    : super(const NoticesState());

  void loadNotifications() {
    _subscription?.cancel();
    _subscription = _repository.watchUnmarkedNotifications().listen(
      (notifications) {
        emit(state.copyWith(
          notifications: notifications,
          status: UiFlowStatus.success,
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          error: error,
          status: UiFlowStatus.failure,
        ));
      },
    );
  }

  Future<void> markAsReceived(String id) async {
    await tryOperation(() async {
      await _repository.markAsReceived(id);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: NotificationOperation.markAsReceived,
      );
    });
  }

  Future<void> dismiss(String id) async {
    await tryOperation(() async {
      await _repository.dismiss(id);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: NotificationOperation.dismiss,
      );
    });
  }

  Future<void> markAllAsReceived() async {
    await tryOperation(() async {
      await _repository.markAllAsReceived();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: NotificationOperation.markAllAsReceived,
      );
    }, emitLoading: true);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

@freezed
class NoticesState with _$NoticesState, UiFlowStateMixin implements IUiFlowState {
  const factory NoticesState({
    @Default([]) List<NotificationData> notifications,
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    NotificationOperation? lastOperation,
  }) = _NoticesState;

  const NoticesState._();
}

enum NotificationOperation {
  markAsReceived,
  dismiss,
  markAllAsReceived,
}
