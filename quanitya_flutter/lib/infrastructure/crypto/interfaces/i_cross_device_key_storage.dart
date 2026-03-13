/// Interface for cross-device key storage backends.
///
/// Abstracts the platform-specific mechanism for syncing a device key
/// across a user's devices:
/// - iOS: iCloud Keychain (`synchronizable: true`)
/// - Android: Google Block Store (`shouldBackupToCloud: true`)
///
/// Each platform provides one implementation, registered via DI.
/// Business logic (CryptoKeyRepository, AuthService, DeviceManagementCubit)
/// uses this interface — no platform checks needed.
abstract class ICrossDeviceKeyStorage {
  /// Whether this storage backend is available on the current platform.
  ///
  /// Returns false on unsupported platforms (e.g., iCloud on Android).
  /// Callers should check this before calling [store], [retrieve], [delete].
  bool get isAvailable;

  /// Human-readable label for the device entry on the server.
  ///
  /// Examples: "iCloud", "Google Backup".
  /// Used as the device label when registering with the server,
  /// and to identify the cross-device entry in the device list UI.
  String get deviceLabel;

  /// Store a device key JWK in the cross-device storage.
  Future<void> store(String jwk);

  /// Retrieve the device key JWK from cross-device storage.
  /// Returns null if not found.
  Future<String?> retrieve();

  /// Delete the device key from cross-device storage.
  Future<void> delete();
}
