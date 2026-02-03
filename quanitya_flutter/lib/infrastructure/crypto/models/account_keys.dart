import 'package:dart_jwk_duo/dart_jwk_duo.dart';

/// Account keys containing all cryptographic keys for a user account
/// 
/// This model represents the complete set of keys generated during account creation:
/// - Ultimate Key Duo: Long-term recovery keys (4096-bit) using dart_jwk_duo IKeyDuo
/// - Device Key Duo: Daily-use keys (3072-bit) using dart_jwk_duo IKeyDuo
/// - Symmetric Data Key: AES-256 key for data encryption
/// - Recovery Blob: SDK encrypted with Ultimate Public Key
/// - Device Blob: SDK encrypted with Device Public Key
class AccountKeys {
  final IKeyDuo ultimateKeys;    // Use dart_jwk_duo type directly
  final IKeyDuo deviceKeys;      // Use dart_jwk_duo type directly
  final String symmetricDataKey; // AES-256 key as base64 string
  final String recoveryBlob;     // SDK encrypted with Ultimate Public Key
  final String deviceBlob;       // SDK encrypted with Device Public Key
  
  const AccountKeys({
    required this.ultimateKeys,
    required this.deviceKeys,
    required this.symmetricDataKey,
    required this.recoveryBlob,
    required this.deviceBlob,
  });
}