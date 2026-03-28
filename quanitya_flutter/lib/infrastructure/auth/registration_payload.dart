import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'registration_payload.freezed.dart';
part 'registration_payload.g.dart';

/// Pre-prepared registration payload created during account creation.
/// 
/// This payload contains everything needed to register with the server,
/// signed by the ultimate key to prove all keys belong together.
/// 
/// Created during [AuthService.createAccount] and stored in secure storage.
/// Retrieved and sent during [AuthService.registerAccountWithServer].
@freezed
abstract class RegistrationPayload with _$RegistrationPayload {
  const RegistrationPayload._();
  const factory RegistrationPayload({
    /// Device signing public key (ECDSA P-256, 128-char hex)
    /// Used as the account's publicMasterKey on server
    required String devicePublicKeyHex,
    
    /// Ultimate signing public key (ECDSA P-256, 128-char hex)
    /// Used for account lookup during recovery
    required String ultimatePublicKeyHex,
    
    /// Encrypted symmetric key blob for recovery
    /// Encrypted with ultimate encryption public key
    required String recoveryBlob,
    
    /// Encrypted symmetric key blob for this device
    /// Encrypted with device encryption public key
    required String deviceBlob,
    
    /// Signature of the payload data by the ultimate signing key
    /// Proves all keys were created together and haven't been tampered with
    required String signature,

    /// Attestation: ultimate key's ECDSA signature over devicePublicKeyHex.
    /// Proves the account owner authorized this device key.
    required String deviceKeyAttestation,

    /// Attestation for the cross-device key (iCloud/BlockStore), if generated.
    /// Same format: ultimate key's ECDSA signature over cross-device public key hex.
    String? crossDeviceKeyAttestation,

    /// Timestamp when the payload was created
    required DateTime createdAt,

    /// Version for future compatibility
    @Default(1) int version,
  }) = _RegistrationPayload;

  factory RegistrationPayload.fromJson(Map<String, dynamic> json) =>
      _$RegistrationPayloadFromJson(json);
}

/// Extension methods for RegistrationPayload
extension RegistrationPayloadX on RegistrationPayload {
  /// Get the data that was signed (for verification)
  String get signableData => '$devicePublicKeyHex:$ultimatePublicKeyHex:$recoveryBlob:$deviceBlob:${createdAt.toIso8601String()}';
  
  /// Serialize to JSON string for storage
  String toJsonString() => jsonEncode(toJson());
  
  /// Deserialize from JSON string
  static RegistrationPayload fromJsonString(String json) =>
      RegistrationPayload.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
