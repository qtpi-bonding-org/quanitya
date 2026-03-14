/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'future_calls_generated_models/monthly_archival_future_call_run_monthly_archival_model.dart'
    as _i2;
import 'future_calls_generated_models/monthly_archival_future_call_initialize_schedule_model.dart'
    as _i3;
import 'future_calls_generated_models/monthly_backup_future_call_run_monthly_backup_model.dart'
    as _i4;
import 'future_calls_generated_models/monthly_backup_future_call_initialize_schedule_model.dart'
    as _i5;
import 'dart:async' as _i6;
import '../future_calls/monthly_archival_future_call.dart' as _i7;
import '../future_calls/monthly_backup_future_call.dart' as _i8;

/// Invokes a future call.
typedef _InvokeFutureCall =
    Future<void> Function(String name, _i1.SerializableModel? object);

extension ServerpodFutureCallsGetter on _i1.Serverpod {
  /// Generated future calls.
  FutureCalls get futureCalls => FutureCalls();
}

class FutureCalls extends _i1.FutureCallDispatch<_FutureCallRef> {
  FutureCalls._();

  factory FutureCalls() {
    return _instance;
  }

  static final FutureCalls _instance = FutureCalls._();

  _i1.FutureCallManager? _futureCallManager;

  String? _serverId;

  String get _effectiveServerId {
    if (_serverId == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _serverId!;
  }

  _i1.FutureCallManager get _effectiveFutureCallManager {
    if (_futureCallManager == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _futureCallManager!;
  }

  @override
  void initialize(
    _i1.FutureCallManager futureCallManager,
    String serverId,
  ) {
    var registeredFutureCalls = <String, _i1.FutureCall>{
      'MonthlyArchivalRunMonthlyArchivalFutureCall':
          MonthlyArchivalRunMonthlyArchivalFutureCall(),
      'MonthlyArchivalInitializeScheduleFutureCall':
          MonthlyArchivalInitializeScheduleFutureCall(),
      'MonthlyBackupRunMonthlyBackupFutureCall':
          MonthlyBackupRunMonthlyBackupFutureCall(),
      'MonthlyBackupInitializeScheduleFutureCall':
          MonthlyBackupInitializeScheduleFutureCall(),
    };
    _futureCallManager = futureCallManager;
    _serverId = serverId;
    for (final entry in registeredFutureCalls.entries) {
      _futureCallManager?.registerFutureCall(entry.value, entry.key);
    }
  }

  @override
  _FutureCallRef callAtTime(
    DateTime time, {
    String? identifier,
  }) {
    return _FutureCallRef(
      (name, object) {
        return _effectiveFutureCallManager.scheduleFutureCall(
          name,
          object,
          time,
          _effectiveServerId,
          identifier,
        );
      },
    );
  }

  @override
  _FutureCallRef callWithDelay(
    Duration delay, {
    String? identifier,
  }) {
    return _FutureCallRef(
      (name, object) {
        return _effectiveFutureCallManager.scheduleFutureCall(
          name,
          object,
          DateTime.now().toUtc().add(delay),
          _effectiveServerId,
          identifier,
        );
      },
    );
  }

  @override
  Future<void> cancel(String identifier) async {
    await _effectiveFutureCallManager.cancelFutureCall(identifier);
  }
}

class _FutureCallRef {
  _FutureCallRef(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  late final monthlyArchival = _MonthlyArchivalFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final monthlyBackup = _MonthlyBackupFutureCallDispatcher(
    _invokeFutureCall,
  );
}

class _MonthlyArchivalFutureCallDispatcher {
  _MonthlyArchivalFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> runMonthlyArchival(int iteration) {
    var object = _i2.MonthlyArchivalFutureCallRunMonthlyArchivalModel(
      iteration: iteration,
    );
    return _invokeFutureCall(
      'MonthlyArchivalRunMonthlyArchivalFutureCall',
      object,
    );
  }

  Future<void> initializeSchedule(int iteration) {
    var object = _i3.MonthlyArchivalFutureCallInitializeScheduleModel(
      iteration: iteration,
    );
    return _invokeFutureCall(
      'MonthlyArchivalInitializeScheduleFutureCall',
      object,
    );
  }
}

class _MonthlyBackupFutureCallDispatcher {
  _MonthlyBackupFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> runMonthlyBackup(int iteration) {
    var object = _i4.MonthlyBackupFutureCallRunMonthlyBackupModel(
      iteration: iteration,
    );
    return _invokeFutureCall(
      'MonthlyBackupRunMonthlyBackupFutureCall',
      object,
    );
  }

  Future<void> initializeSchedule(int iteration) {
    var object = _i5.MonthlyBackupFutureCallInitializeScheduleModel(
      iteration: iteration,
    );
    return _invokeFutureCall(
      'MonthlyBackupInitializeScheduleFutureCall',
      object,
    );
  }
}

/// Public method that schedules the next run and executes the task
///
/// This method will be available in generated code after running `serverpod generate`
class MonthlyArchivalRunMonthlyArchivalFutureCall
    extends
        _i1.FutureCall<_i2.MonthlyArchivalFutureCallRunMonthlyArchivalModel> {
  @override
  _i6.Future<void> invoke(
    _i1.Session session,
    _i2.MonthlyArchivalFutureCallRunMonthlyArchivalModel? object,
  ) async {
    if (object != null) {
      await _i7.MonthlyArchivalFutureCall().runMonthlyArchival(
        session,
        object.iteration,
      );
    }
  }
}

/// Initialize the monthly archival schedule
///
/// Call this once during server startup to begin the recurring schedule
class MonthlyArchivalInitializeScheduleFutureCall
    extends
        _i1.FutureCall<_i3.MonthlyArchivalFutureCallInitializeScheduleModel> {
  @override
  _i6.Future<void> invoke(
    _i1.Session session,
    _i3.MonthlyArchivalFutureCallInitializeScheduleModel? object,
  ) async {
    if (object != null) {
      await _i7.MonthlyArchivalFutureCall().initializeSchedule(
        session,
        object.iteration,
      );
    }
  }
}

/// Public method called by Serverpod's generated invoke wrapper.
class MonthlyBackupRunMonthlyBackupFutureCall
    extends _i1.FutureCall<_i4.MonthlyBackupFutureCallRunMonthlyBackupModel> {
  @override
  _i6.Future<void> invoke(
    _i1.Session session,
    _i4.MonthlyBackupFutureCallRunMonthlyBackupModel? object,
  ) async {
    if (object != null) {
      await _i8.MonthlyBackupFutureCall().runMonthlyBackup(
        session,
        object.iteration,
      );
    }
  }
}

/// Bootstrap the schedule on server startup.
class MonthlyBackupInitializeScheduleFutureCall
    extends _i1.FutureCall<_i5.MonthlyBackupFutureCallInitializeScheduleModel> {
  @override
  _i6.Future<void> invoke(
    _i1.Session session,
    _i5.MonthlyBackupFutureCallInitializeScheduleModel? object,
  ) async {
    if (object != null) {
      await _i8.MonthlyBackupFutureCall().initializeSchedule(
        session,
        object.iteration,
      );
    }
  }
}
