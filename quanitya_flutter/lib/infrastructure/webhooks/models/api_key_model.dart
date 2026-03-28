import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_key_model.freezed.dart';
part 'api_key_model.g.dart';

/// Authentication type for API keys
enum AuthType {
  /// Bearer token: Authorization: Bearer &lt;token&gt;
  bearer,
  /// API key in custom header: &lt;headerName&gt;: &lt;value&gt;
  apiKeyHeader,
}

/// Model for API key metadata
/// 
/// Actual key value stored in flutter_secure_storage, not here.
@freezed
abstract class ApiKeyModel with _$ApiKeyModel {
  const ApiKeyModel._();
  const factory ApiKeyModel({
    required String id,
    required String name,
    required AuthType authType,
    String? headerName,  // Required for apiKeyHeader type
    required String secureStorageKey,
    required DateTime updatedAt,
  }) = _ApiKeyModel;

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) => _$ApiKeyModelFromJson(json);
}
