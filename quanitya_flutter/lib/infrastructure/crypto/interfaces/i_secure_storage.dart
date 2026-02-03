/// Interface for secure storage of cryptographic keys (JWK format).
///
/// Provides secure storage operations using platform-specific secure storage
/// mechanisms (iOS Keychain, Android Keystore).
///
/// Naming convention (matches ICryptoKeyRepository):
/// - No "Public" in name = contains private key material
/// - All keys stored as JWK JSON strings
abstract class ISecureStorage {
  /// Store device key (JWK Set with private keys) in secure enclave.
  Future<void> storeDeviceKey(String jwk);

  /// Store symmetric data key (JWK) in secure enclave.
  Future<void> storeSymmetricDataKey(String jwk);

  /// Retrieve device key (JWK Set with private keys) from secure storage.
  /// Returns null if not found.
  Future<String?> getDeviceKey();

  /// Retrieve symmetric data key (JWK) from secure storage.
  /// Returns null if not found.
  Future<String?> getSymmetricDataKey();

  /// Clear all stored keys from secure storage.
  /// Call during logout or account reset.
  Future<void> clearAllKeys();

  /// Store arbitrary secure data with a custom key.
  /// Used for temporary secure storage needs like registration payloads.
  Future<void> storeSecureData(String key, String value);

  /// Retrieve arbitrary secure data by key.
  /// Returns null if not found.
  Future<String?> getSecureData(String key);

  /// Delete arbitrary secure data by key.
  Future<void> deleteSecureData(String key);

  /// Store data with platform-specific options (iOS Keychain sync, etc.).
  /// On iOS: supports iCloud Keychain synchronization
  /// On other platforms: falls back to regular secure storage
  Future<void> storeWithPlatformOptions({
    required String key,
    required String value,
    bool synchronizable = false,
  });

  /// Retrieve data stored with platform-specific options.
  Future<String?> getWithPlatformOptions({
    required String key,
    bool synchronizable = false,
  });

  /// Delete data stored with platform-specific options.
  Future<void> deleteWithPlatformOptions({
    required String key,
    bool synchronizable = false,
  });
}
