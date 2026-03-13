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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class SyncTierBalance implements _i1.SerializableModel {
  SyncTierBalance._({
    required this.consumableType,
    required this.balance,
  });

  factory SyncTierBalance({
    required int consumableType,
    required int balance,
  }) = _SyncTierBalanceImpl;

  factory SyncTierBalance.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncTierBalance(
      consumableType: jsonSerialization['consumableType'] as int,
      balance: jsonSerialization['balance'] as int,
    );
  }

  int consumableType;

  int balance;

  /// Returns a shallow copy of this [SyncTierBalance]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncTierBalance copyWith({
    int? consumableType,
    int? balance,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncTierBalance',
      'consumableType': consumableType,
      'balance': balance,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SyncTierBalanceImpl extends SyncTierBalance {
  _SyncTierBalanceImpl({
    required int consumableType,
    required int balance,
  }) : super._(
         consumableType: consumableType,
         balance: balance,
       );

  /// Returns a shallow copy of this [SyncTierBalance]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncTierBalance copyWith({
    int? consumableType,
    int? balance,
  }) {
    return SyncTierBalance(
      consumableType: consumableType ?? this.consumableType,
      balance: balance ?? this.balance,
    );
  }
}
