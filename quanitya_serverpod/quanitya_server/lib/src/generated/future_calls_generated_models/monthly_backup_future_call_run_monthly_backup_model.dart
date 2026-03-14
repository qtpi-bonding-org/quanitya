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

abstract class MonthlyBackupFutureCallRunMonthlyBackupModel
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MonthlyBackupFutureCallRunMonthlyBackupModel._({required this.iteration});

  factory MonthlyBackupFutureCallRunMonthlyBackupModel({
    required int iteration,
  }) = _MonthlyBackupFutureCallRunMonthlyBackupModelImpl;

  factory MonthlyBackupFutureCallRunMonthlyBackupModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MonthlyBackupFutureCallRunMonthlyBackupModel(
      iteration: jsonSerialization['iteration'] as int,
    );
  }

  int iteration;

  /// Returns a shallow copy of this [MonthlyBackupFutureCallRunMonthlyBackupModel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MonthlyBackupFutureCallRunMonthlyBackupModel copyWith({int? iteration});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.MonthlyBackupFutureCallRunMonthlyBackupModel',
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

class _MonthlyBackupFutureCallRunMonthlyBackupModelImpl
    extends MonthlyBackupFutureCallRunMonthlyBackupModel {
  _MonthlyBackupFutureCallRunMonthlyBackupModelImpl({required int iteration})
    : super._(iteration: iteration);

  /// Returns a shallow copy of this [MonthlyBackupFutureCallRunMonthlyBackupModel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MonthlyBackupFutureCallRunMonthlyBackupModel copyWith({int? iteration}) {
    return MonthlyBackupFutureCallRunMonthlyBackupModel(
      iteration: iteration ?? this.iteration,
    );
  }
}
