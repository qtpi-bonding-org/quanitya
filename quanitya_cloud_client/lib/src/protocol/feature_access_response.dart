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

abstract class FeatureAccessResponse implements _i1.SerializableModel {
  FeatureAccessResponse._({
    required this.hasSync,
    required this.hasIntegrations,
    required this.sync500MbDaysRemaining,
    required this.sync1GbDaysRemaining,
    required this.sync2GbDaysRemaining,
    required this.sync4GbDaysRemaining,
    required this.integrationDaysRemaining,
    required this.analysisCredits,
    required this.llmCalls,
  });

  factory FeatureAccessResponse({
    required bool hasSync,
    required bool hasIntegrations,
    required int sync500MbDaysRemaining,
    required int sync1GbDaysRemaining,
    required int sync2GbDaysRemaining,
    required int sync4GbDaysRemaining,
    required int integrationDaysRemaining,
    required int analysisCredits,
    required int llmCalls,
  }) = _FeatureAccessResponseImpl;

  factory FeatureAccessResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return FeatureAccessResponse(
      hasSync: _i1.BoolJsonExtension.fromJson(jsonSerialization['hasSync']),
      hasIntegrations: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['hasIntegrations'],
      ),
      sync500MbDaysRemaining:
          jsonSerialization['sync500MbDaysRemaining'] as int,
      sync1GbDaysRemaining: jsonSerialization['sync1GbDaysRemaining'] as int,
      sync2GbDaysRemaining: jsonSerialization['sync2GbDaysRemaining'] as int,
      sync4GbDaysRemaining: jsonSerialization['sync4GbDaysRemaining'] as int,
      integrationDaysRemaining:
          jsonSerialization['integrationDaysRemaining'] as int,
      analysisCredits: jsonSerialization['analysisCredits'] as int,
      llmCalls: jsonSerialization['llmCalls'] as int,
    );
  }

  bool hasSync;

  bool hasIntegrations;

  int sync500MbDaysRemaining;

  int sync1GbDaysRemaining;

  int sync2GbDaysRemaining;

  int sync4GbDaysRemaining;

  int integrationDaysRemaining;

  int analysisCredits;

  int llmCalls;

  /// Returns a shallow copy of this [FeatureAccessResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FeatureAccessResponse copyWith({
    bool? hasSync,
    bool? hasIntegrations,
    int? sync500MbDaysRemaining,
    int? sync1GbDaysRemaining,
    int? sync2GbDaysRemaining,
    int? sync4GbDaysRemaining,
    int? integrationDaysRemaining,
    int? analysisCredits,
    int? llmCalls,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FeatureAccessResponse',
      'hasSync': hasSync,
      'hasIntegrations': hasIntegrations,
      'sync500MbDaysRemaining': sync500MbDaysRemaining,
      'sync1GbDaysRemaining': sync1GbDaysRemaining,
      'sync2GbDaysRemaining': sync2GbDaysRemaining,
      'sync4GbDaysRemaining': sync4GbDaysRemaining,
      'integrationDaysRemaining': integrationDaysRemaining,
      'analysisCredits': analysisCredits,
      'llmCalls': llmCalls,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _FeatureAccessResponseImpl extends FeatureAccessResponse {
  _FeatureAccessResponseImpl({
    required bool hasSync,
    required bool hasIntegrations,
    required int sync500MbDaysRemaining,
    required int sync1GbDaysRemaining,
    required int sync2GbDaysRemaining,
    required int sync4GbDaysRemaining,
    required int integrationDaysRemaining,
    required int analysisCredits,
    required int llmCalls,
  }) : super._(
         hasSync: hasSync,
         hasIntegrations: hasIntegrations,
         sync500MbDaysRemaining: sync500MbDaysRemaining,
         sync1GbDaysRemaining: sync1GbDaysRemaining,
         sync2GbDaysRemaining: sync2GbDaysRemaining,
         sync4GbDaysRemaining: sync4GbDaysRemaining,
         integrationDaysRemaining: integrationDaysRemaining,
         analysisCredits: analysisCredits,
         llmCalls: llmCalls,
       );

  /// Returns a shallow copy of this [FeatureAccessResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FeatureAccessResponse copyWith({
    bool? hasSync,
    bool? hasIntegrations,
    int? sync500MbDaysRemaining,
    int? sync1GbDaysRemaining,
    int? sync2GbDaysRemaining,
    int? sync4GbDaysRemaining,
    int? integrationDaysRemaining,
    int? analysisCredits,
    int? llmCalls,
  }) {
    return FeatureAccessResponse(
      hasSync: hasSync ?? this.hasSync,
      hasIntegrations: hasIntegrations ?? this.hasIntegrations,
      sync500MbDaysRemaining:
          sync500MbDaysRemaining ?? this.sync500MbDaysRemaining,
      sync1GbDaysRemaining: sync1GbDaysRemaining ?? this.sync1GbDaysRemaining,
      sync2GbDaysRemaining: sync2GbDaysRemaining ?? this.sync2GbDaysRemaining,
      sync4GbDaysRemaining: sync4GbDaysRemaining ?? this.sync4GbDaysRemaining,
      integrationDaysRemaining:
          integrationDaysRemaining ?? this.integrationDaysRemaining,
      analysisCredits: analysisCredits ?? this.analysisCredits,
      llmCalls: llmCalls ?? this.llmCalls,
    );
  }
}
