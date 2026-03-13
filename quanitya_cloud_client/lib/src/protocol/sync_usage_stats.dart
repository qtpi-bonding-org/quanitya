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

abstract class SyncUsageStats implements _i1.SerializableModel {
  SyncUsageStats._({
    required this.currentBalance,
    required this.dailyConsumption,
    required this.daysUntilExpiry,
    this.estimatedExpiryDate,
    required this.isActive,
    this.recommendedTopUp,
  });

  factory SyncUsageStats({
    required int currentBalance,
    required double dailyConsumption,
    required int daysUntilExpiry,
    String? estimatedExpiryDate,
    required bool isActive,
    int? recommendedTopUp,
  }) = _SyncUsageStatsImpl;

  factory SyncUsageStats.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncUsageStats(
      currentBalance: jsonSerialization['currentBalance'] as int,
      dailyConsumption: (jsonSerialization['dailyConsumption'] as num)
          .toDouble(),
      daysUntilExpiry: jsonSerialization['daysUntilExpiry'] as int,
      estimatedExpiryDate: jsonSerialization['estimatedExpiryDate'] as String?,
      isActive: _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
      recommendedTopUp: jsonSerialization['recommendedTopUp'] as int?,
    );
  }

  int currentBalance;

  double dailyConsumption;

  int daysUntilExpiry;

  String? estimatedExpiryDate;

  bool isActive;

  int? recommendedTopUp;

  /// Returns a shallow copy of this [SyncUsageStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncUsageStats copyWith({
    int? currentBalance,
    double? dailyConsumption,
    int? daysUntilExpiry,
    String? estimatedExpiryDate,
    bool? isActive,
    int? recommendedTopUp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncUsageStats',
      'currentBalance': currentBalance,
      'dailyConsumption': dailyConsumption,
      'daysUntilExpiry': daysUntilExpiry,
      if (estimatedExpiryDate != null)
        'estimatedExpiryDate': estimatedExpiryDate,
      'isActive': isActive,
      if (recommendedTopUp != null) 'recommendedTopUp': recommendedTopUp,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncUsageStatsImpl extends SyncUsageStats {
  _SyncUsageStatsImpl({
    required int currentBalance,
    required double dailyConsumption,
    required int daysUntilExpiry,
    String? estimatedExpiryDate,
    required bool isActive,
    int? recommendedTopUp,
  }) : super._(
         currentBalance: currentBalance,
         dailyConsumption: dailyConsumption,
         daysUntilExpiry: daysUntilExpiry,
         estimatedExpiryDate: estimatedExpiryDate,
         isActive: isActive,
         recommendedTopUp: recommendedTopUp,
       );

  /// Returns a shallow copy of this [SyncUsageStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncUsageStats copyWith({
    int? currentBalance,
    double? dailyConsumption,
    int? daysUntilExpiry,
    Object? estimatedExpiryDate = _Undefined,
    bool? isActive,
    Object? recommendedTopUp = _Undefined,
  }) {
    return SyncUsageStats(
      currentBalance: currentBalance ?? this.currentBalance,
      dailyConsumption: dailyConsumption ?? this.dailyConsumption,
      daysUntilExpiry: daysUntilExpiry ?? this.daysUntilExpiry,
      estimatedExpiryDate: estimatedExpiryDate is String?
          ? estimatedExpiryDate
          : this.estimatedExpiryDate,
      isActive: isActive ?? this.isActive,
      recommendedTopUp: recommendedTopUp is int?
          ? recommendedTopUp
          : this.recommendedTopUp,
    );
  }
}
