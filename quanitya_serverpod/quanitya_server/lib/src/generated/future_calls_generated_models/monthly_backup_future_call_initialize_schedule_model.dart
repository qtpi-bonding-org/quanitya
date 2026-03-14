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

abstract class MonthlyBackupFutureCallInitializeScheduleModel
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MonthlyBackupFutureCallInitializeScheduleModel._({required this.iteration});

  factory MonthlyBackupFutureCallInitializeScheduleModel({
    required int iteration,
  }) = _MonthlyBackupFutureCallInitializeScheduleModelImpl;

  factory MonthlyBackupFutureCallInitializeScheduleModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MonthlyBackupFutureCallInitializeScheduleModel(
      iteration: jsonSerialization['iteration'] as int,
    );
  }

  int iteration;

  /// Returns a shallow copy of this [MonthlyBackupFutureCallInitializeScheduleModel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MonthlyBackupFutureCallInitializeScheduleModel copyWith({int? iteration});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__':
          'quanitya.MonthlyBackupFutureCallInitializeScheduleModel',
      'iteration': iteration,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _MonthlyBackupFutureCallInitializeScheduleModelImpl
    extends MonthlyBackupFutureCallInitializeScheduleModel {
  _MonthlyBackupFutureCallInitializeScheduleModelImpl({required int iteration})
    : super._(iteration: iteration);

  /// Returns a shallow copy of this [MonthlyBackupFutureCallInitializeScheduleModel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MonthlyBackupFutureCallInitializeScheduleModel copyWith({int? iteration}) {
    return MonthlyBackupFutureCallInitializeScheduleModel(
      iteration: iteration ?? this.iteration,
    );
  }
}
