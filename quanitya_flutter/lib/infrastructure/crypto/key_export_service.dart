import 'dart:io';

import 'package:dart_jwk_duo/dart_jwk_duo.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

import '../core/try_operation.dart';
import 'interfaces/i_secure_storage.dart';
import 'exceptions/crypto_exceptions.dart';
import 'utils/crypto_logger.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// KEY EXPORT SERVICE
// ═══════════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// Handles export of the Ultimate Key JWK to external storage mechanisms
// for user backup and cross-device recovery.
//
// EXPORT METHODS:
// - iCloud Keychain (iOS only) - Syncs via iOS Keychain with synchronizable flag
// - Share sheet - Native share for saving to files, AirDrop, etc.
// - Clipboard - Simple copy for pasting into password managers
//
// SECURITY NOTES:
// - This service receives the JWK as an argument (does NOT retrieve it)
// - Caller is responsible for obtaining the key via getUltimateKeyJwkOnce()
// - iCloud sync uses iOS Keychain's synchronizable attribute
// - All operations are logged via CryptoLogger (without key content)
//
// ═══════════════════════════════════════════════════════════════════════════════

/// Result of a key export operation.
enum KeyExportResult {
  /// Export completed successfully
  success,

  /// User cancelled the export (e.g., dismissed share sheet)
  cancelled,

  /// Export failed due to an error
  failed,

  /// Operation not available on this platform
  unavailable,
}

/// Generates the iCloud Keychain storage key for an ultimate key.
/// Format: quanitya_ultimate_{ultimateSigningPublicKeyHex}
/// This prevents collisions if multiple accounts exist on the same device.
String _iCloudKeyId(String ultimateHex) => 'quanitya_ultimate_$ultimateHex';

/// Generates the export filename for an ultimate key.
/// Format: quanitya_ultimate_{ultimateSigningPublicKeyHex}.jwk
/// Same naming as iCloud Keychain key for consistency.
String _exportFilename(String ultimateHex) =>
    'quanitya_ultimate_$ultimateHex.jwk';

/// Service for exporting cryptographic keys to external storage.
///
/// Takes the JWK as an argument - does NOT depend on ICryptoKeyRepository.
/// This keeps the service focused on export mechanics only.
@lazySingleton
class KeyExportService {
  final ISecureStorage _secureStorage;

  KeyExportService(this._secureStorage);

  // ─────────────────────────────────────────────────────────────────────────────
  // iCloud Keychain Export (iOS only)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Check if iCloud Keychain sync is available.
  bool get isICloudAvailable => Platform.isIOS;

  /// Export key to iCloud Keychain (iOS only).
  ///
  /// Stores the key in iOS Keychain with `synchronizable: true`, which
  /// automatically syncs to iCloud Keychain on all user's Apple devices.
  ///
  /// The storage key is derived from the JWK's signing public key hex,
  /// ensuring each account has a unique keychain entry.
  ///
  /// Validates the JWK before export to ensure it's a complete, working KeyDuo.
  ///
  /// [jwk] - The JWK JSON string to export (typically Ultimate Key).
  ///
  /// Returns [KeyExportResult.unavailable] on non-iOS platforms.
  Future<KeyExportResult> saveToICloudKeychain({
    required String jwk,
  }) {
    return tryMethod(
      () async {
        if (!Platform.isIOS) {
          CryptoLogger.logSecurityEvent(
              'iCloud Keychain not available (not iOS)');
          return KeyExportResult.unavailable;
        }

        if (jwk.trim().isEmpty) {
          throw const ValidationException('Cannot export empty key');
        }

        CryptoLogger.logSecurityEvent(
            'Verifying and saving ultimate key to iCloud Keychain');

        // Verify JWK and get hex in one step
        final ultimateHex = await verifyAndGetHex(jwk);

        await _secureStorage.storeWithPlatformOptions(
          key: _iCloudKeyId(ultimateHex),
          value: jwk,
          synchronizable: true,
        );

        CryptoLogger.logSuccess('saveToICloudKeychain');
        return KeyExportResult.success;
      },
      CryptoOperationException.new,
      'saveToICloudKeychain',
    );
  }

  /// Retrieve key from iCloud Keychain (iOS only).
  ///
  /// Use during recovery flow on a new device to retrieve the ultimate key
  /// that was synced via iCloud Keychain.
  ///
  /// [ultimateHex] - The ultimate signing public key hex (128 chars) to look up.
  ///                 This is the account identifier the user provides during recovery.
  ///
  /// Returns null if not found or not on iOS.
  Future<String?> getFromICloudKeychain({
    required String ultimateHex,
  }) {
    return tryMethod(
      () async {
        if (!Platform.isIOS) {
          return null;
        }

        if (ultimateHex.trim().isEmpty) {
          return null;
        }

        CryptoLogger.logSecurityEvent(
            'Retrieving ultimate key from iCloud Keychain');

        final jwk = await _secureStorage.getWithPlatformOptions(
          key: _iCloudKeyId(ultimateHex),
          synchronizable: true,
        );

        if (jwk != null) {
          CryptoLogger.logSuccess('getFromICloudKeychain');
        } else {
          CryptoLogger.logSecurityEvent(
              'No ultimate key found in iCloud Keychain');
        }

        return jwk;
      },
      CryptoOperationException.new,
      'getFromICloudKeychain',
    );
  }

  /// Delete key from iCloud Keychain (iOS only).
  ///
  /// Call during account deletion or when user wants to remove cloud backup.
  ///
  /// [jwk] - The JWK to delete (hex is derived from it).
  Future<void> deleteFromICloudKeychain({
    required String jwk,
  }) {
    return tryMethod(
      () async {
        if (!Platform.isIOS) return;

        if (jwk.trim().isEmpty) return;

        CryptoLogger.logSecurityEvent(
            'Deleting ultimate key from iCloud Keychain');

        final ultimateHex = await getSigningPublicKeyHex(jwk);

        await _secureStorage.deleteWithPlatformOptions(
          key: _iCloudKeyId(ultimateHex),
          synchronizable: true,
        );

        CryptoLogger.logSuccess('deleteFromICloudKeychain');
      },
      CryptoOperationException.new,
      'deleteFromICloudKeychain',
    );
  }

  /// Extract signing public key hex from JWK.
  ///
  /// Parses the JWK Set and exports the ECDSA P-256 signing public key
  /// as a 128-char hex string (x + y coordinates, no 04 prefix).
  ///
  /// Use this to get the account identifier from an ultimate key JWK.
  /// This is the same hex used for iCloud Keychain storage keys.
  ///
  /// This goes through the full webcrypto import/export path to ensure
  /// the hex is derived exactly the same way as [SigningKeyPair.exportPublicKeyHex].
  Future<String> getSigningPublicKeyHex(String jwk) {
    return tryMethod(
      () async {
        if (jwk.trim().isEmpty) {
          throw const ValidationException('Cannot extract hex from empty JWK');
        }

        try {
          return await KeyDuoSerializer.extractSigningPublicKeyHex(jwk);
        } on FormatException catch (e) {
          throw ValidationException('Invalid JWK format: ${e.message}', e);
        }
      },
      ValidationException.new,
      'getSigningPublicKeyHex',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Verification
  // ─────────────────────────────────────────────────────────────────────────────

  /// Verify that a JWK is a complete, working KeyDuo with private keys.
  ///
  /// Uses dart_jwk_duo's verifyJwk which:
  /// 1. Parses and validates JWK structure
  /// 2. Imports keys via webcrypto
  /// 3. Runs cryptographic roundtrips (sign/verify, encrypt/decrypt)
  ///
  /// Throws [ValidationException] with details if verification fails.
  /// Returns the signing public key hex on success (for convenience).
  Future<String> verifyAndGetHex(String jwk) {
    return tryMethod(
      () async {
        if (jwk.trim().isEmpty) {
          throw const ValidationException('JWK cannot be empty');
        }

        try {
          final KeyDuo keyDuo = await KeyDuoSerializer.verifyJwk(jwk);
          CryptoLogger.logSuccess('verifyAndGetHex');
          return await keyDuo.signingKeyPair.exportPublicKeyHex();
        } on FormatException catch (e) {
          throw ValidationException('Invalid JWK format: ${e.message}', e);
        } on StateError catch (e) {
          throw ValidationException('Key verification failed: ${e.message}', e);
        }
      },
      ValidationException.new,
      'verifyAndGetHex',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Share Sheet Export
  // ─────────────────────────────────────────────────────────────────────────────

  /// Export key via native share sheet as a file.
  ///
  /// On iOS: User can save to Files (including iCloud Drive), AirDrop, etc.
  /// On Android: Standard share sheet with various export options.
  ///
  /// Filename is derived from the JWK's signing public key hex:
  /// `quanitya_ultimate_{hex}.jwk` - same naming as iCloud Keychain key.
  ///
  /// Validates the JWK before export to ensure it's a complete, working KeyDuo.
  ///
  /// [jwk] - The JWK JSON string to export (typically Ultimate Key).
  ///
  /// Returns [KeyExportResult] indicating success, cancellation, or failure.
  Future<KeyExportResult> shareAsFile({
    required String jwk,
  }) {
    return tryMethod(
      () async {
        if (jwk.trim().isEmpty) {
          throw const ValidationException('Cannot export empty key');
        }

        CryptoLogger.logSecurityEvent(
            'Verifying and initiating key export via share sheet');

        // Verify JWK and get hex in one step
        final ultimateHex = await verifyAndGetHex(jwk);
        final filename = _exportFilename(ultimateHex);

        final result = await Share.shareXFiles(
          [
            XFile.fromData(
              Uint8List.fromList(jwk.codeUnits),
              name: filename,
              mimeType: 'application/json',
            ),
          ],
          subject: 'Recovery Key Backup',
          text: 'Keep this file safe. You will need it to recover your account.',
        );

        switch (result.status) {
          case ShareResultStatus.success:
            CryptoLogger.logSuccess('shareAsFile');
            return KeyExportResult.success;
          case ShareResultStatus.dismissed:
            CryptoLogger.logSecurityEvent('Key export cancelled by user');
            return KeyExportResult.cancelled;
          case ShareResultStatus.unavailable:
            // On web, ShareResultStatus.unavailable is returned even when download works
            // This is a known limitation of the web implementation
            CryptoLogger.logSecurityEvent(
                'Share unavailable status (may still have worked on web)');
            return KeyExportResult.success; // Assume success on web
        }
      },
      CryptoOperationException.new,
      'shareAsFile',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Clipboard Export
  // ─────────────────────────────────────────────────────────────────────────────

  /// Copy key to clipboard.
  ///
  /// User is responsible for pasting and clearing clipboard.
  ///
  /// [jwk] - The JWK JSON string to copy.
  ///
  /// Returns [KeyExportResult.success] on success.
  Future<KeyExportResult> copyToClipboard({
    required String jwk,
  }) {
    return tryMethod(
      () async {
        if (jwk.trim().isEmpty) {
          throw const ValidationException('Cannot copy empty key');
        }

        CryptoLogger.logSecurityEvent('Copying key to clipboard');

        await Clipboard.setData(ClipboardData(text: jwk));

        CryptoLogger.logSuccess('copyToClipboard');
        return KeyExportResult.success;
      },
      CryptoOperationException.new,
      'copyToClipboard',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Local Secure Storage (Biometric-gated)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Store key in local secure storage (NOT synced to iCloud).
  ///
  /// This stores the key on-device only, protected by the platform's
  /// secure enclave. Access should be gated by biometric authentication
  /// (handled by caller via LocalAuthService).
  ///
  /// ⚠️ WARNING: If the device is lost, this key is lost too.
  /// This should be used as a convenience backup, not the only backup.
  ///
  /// [jwk] - The JWK JSON string to store.
  Future<KeyExportResult> storeInSecureStorage({
    required String jwk,
  }) {
    return tryMethod(
      () async {
        if (jwk.trim().isEmpty) {
          throw const ValidationException('Cannot store empty key');
        }

        CryptoLogger.logSecurityEvent(
            'Storing ultimate key in local secure storage');

        final ultimateHex = await verifyAndGetHex(jwk);

        await _secureStorage.storeWithPlatformOptions(
          key: 'quanitya_ultimate_local_$ultimateHex',
          value: jwk,
          synchronizable: false,
        );

        CryptoLogger.logSuccess('storeInSecureStorage');
        return KeyExportResult.success;
      },
      CryptoOperationException.new,
      'storeInSecureStorage',
    );
  }

  /// Retrieve key from local secure storage.
  ///
  /// Access should be gated by biometric authentication (handled by caller).
  ///
  /// [ultimateHex] - The ultimate signing public key hex to look up.
  ///
  /// Returns null if not found.
  Future<String?> getFromSecureStorage({
    required String ultimateHex,
  }) {
    return tryMethod(
      () async {
        if (ultimateHex.trim().isEmpty) {
          return null;
        }

        CryptoLogger.logSecurityEvent(
            'Retrieving ultimate key from local secure storage');

        final jwk = await _secureStorage.getWithPlatformOptions(
          key: 'quanitya_ultimate_local_$ultimateHex',
          synchronizable: false,
        );

        if (jwk != null) {
          CryptoLogger.logSuccess('getFromSecureStorage');
        } else {
          CryptoLogger.logSecurityEvent(
              'No ultimate key found in local secure storage');
        }

        return jwk;
      },
      CryptoOperationException.new,
      'getFromSecureStorage',
    );
  }
}
