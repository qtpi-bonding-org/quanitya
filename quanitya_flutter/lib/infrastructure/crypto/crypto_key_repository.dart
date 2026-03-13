import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:webcrypto/webcrypto.dart';
import 'package:dart_jwk_duo/dart_jwk_duo.dart';
import 'package:flutter/foundation.dart' show Uint8List;

import '../core/try_operation.dart';
import 'interfaces/i_cross_device_key_storage.dart';
import 'interfaces/i_secure_storage.dart';
import 'exceptions/crypto_exceptions.dart';
import 'utils/crypto_logger.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CRYPTO KEY REPOSITORY - AUDITABLE DESIGN
// ═══════════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
// This repository manages cryptographic key lifecycle (generation, storage,
// retrieval) for E2EE. It is a CRUD layer only - no encryption/decryption
// operations happen here.
//
// LIBRARIES USED:
// - webcrypto: W3C Web Crypto API implementation for Dart
//   - AesGcmSecretKey: AES-256-GCM symmetric encryption
//   - EcdhPublicKey/EcdhPrivateKey: ECDH P-256 asymmetric encryption
//   - EcdsaPublicKey/EcdsaPrivateKey: ECDSA P-256 signing (via dart_jwk_duo)
//
// - dart_jwk_duo: Type-safe JWK Set wrapper around webcrypto
//   - KeyDuo: Container for signing + encryption key pairs
//   - KeyDuoGenerator: Generates new KeyDuo instances
//   - KeyDuoSerializer: Import/export KeyDuo as JWK Set JSON
//
// ═══════════════════════════════════════════════════════════════════════════════
// FORMAT RULES (STRICT)
// ═══════════════════════════════════════════════════════════════════════════════
//
// STORAGE FORMAT:
// - All keys stored as JWK JSON strings in secure storage
// - JWK = JSON Web Key (RFC 7517) - portable, standard format
//
// RUNTIME FORMAT:
// - All crypto operations use webcrypto objects (AesGcmSecretKey, KeyDuo, etc.)
// - Never pass raw bytes between layers - always JWK or webcrypto objects
//
// SPECIAL CASE - HEX:
// - Only for device signing public key (ECDSA P-256)
// - Used as Bearer token identifier in auth headers
// - 128-char hex string (64 bytes = x + y coordinates, no 04 prefix)
//
// ═══════════════════════════════════════════════════════════════════════════════
// NAMING CONVENTIONS (STRICT)
// ═══════════════════════════════════════════════════════════════════════════════
//
// METHOD NAME PATTERN: get{KeyType}{Public?}{Format?}{Once?}
//
// {KeyType}:
//   - SymmetricDataKey: AES-256-GCM for E2EE data encryption
//   - DeviceKey: RSA 3072-bit + ECDSA P-256 for daily operations (persisted)
//   - UltimateKey: RSA 4096-bit + ECDSA P-256 for recovery (temporary)
//
// {Public?}:
//   - Absent = PRIVATE key (full keypair, contains private material!)
//   - "Public" = PUBLIC key only (safe to share)
//
// {Format?}:
//   - Absent = webcrypto object (KeyDuo, AesGcmSecretKey, EcdhPublicKey)
//   - "Jwk" = JWK JSON string
//   - "Hex" = hex string (only for signing public key)
//
// {Once?}:
//   - Absent = can retrieve multiple times
//   - "Once" = one-time retrieval, WIPES key from memory after
//
// EXAMPLES:
//   getDeviceKey()              → KeyDuo (private, webcrypto object)
//   getDeviceKeyJwk()           → String (private, JWK JSON)
//   getDevicePublicKey()        → EcdhPublicKey (public, webcrypto object)
//   getDevicePublicKeyJwk()     → String (public, JWK JSON)
//   getUltimateKeyJwkOnce()     → String (private, JWK JSON, WIPES from memory)
//
// ═══════════════════════════════════════════════════════════════════════════════
// KEY TYPES EXPLAINED
// ═══════════════════════════════════════════════════════════════════════════════
//
// SYMMETRIC DATA KEY (AES-256-GCM):
// - Purpose: Encrypt/decrypt user data (E2EE)
// - Storage: Persisted in secure storage as JWK
// - Lifecycle: Created once per account, recovered via blob decryption
//
// DEVICE KEY (KeyDuo: ECDH P-256 + ECDSA P-256):
// - Purpose: Daily signing (auth) and encryption (key wrapping)
// - Storage: Persisted in secure storage as JWK Set
// - Lifecycle: Created per device, can be revoked
// - Contains:
//   - Signing pair (ECDSA P-256): For request signing, auth tokens
//   - Encryption pair (ECDH P-256): For key agreement and hybrid encryption
//
// ULTIMATE KEY (KeyDuo: ECDH P-256 + ECDSA P-256):
// - Purpose: Account recovery, emergency access
// - Storage: IN-MEMORY ONLY, never persisted on device
// - Lifecycle: Generated during account creation, shown once to user
// - Security: getUltimateKeyJwkOnce() WIPES key from memory after retrieval
//
// ═══════════════════════════════════════════════════════════════════════════════
// SECURITY NOTES
// ═══════════════════════════════════════════════════════════════════════════════
//
// - Ultimate private key is NEVER stored - user must save it externally
// - "Once" methods WIPE key from memory after retrieval (not just flagged)
// - All storage goes through ISecureStorage (platform secure enclave)
// - No PII ever touches this layer - only cryptographic material
//
// ═══════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════════

/// Status of crypto keys on this device.
enum CryptoKeyStatus {
  /// No keys exist - first time setup needed
  notInitialized,

  /// Keys exist and are valid
  ready,

  /// Keys exist but may need recovery
  needsRecovery,

  /// No local keys but cross-device key found — auto-recovery possible
  crossDeviceRecoveryAvailable,
}

// ═══════════════════════════════════════════════════════════════════════════════
// Interface
// ═══════════════════════════════════════════════════════════════════════════════

/// Repository interface for cryptographic key CRUD operations.
///
/// This is a pure key management layer - no encryption/decryption happens here.
/// All methods follow strict naming conventions documented at the top of this file.
abstract class ICryptoKeyRepository {
  // ─────────────────────────────────────────────────────────────────────────────
  // Status & Lifecycle
  // ─────────────────────────────────────────────────────────────────────────────

  /// Check current key status on this device.
  Future<CryptoKeyStatus> getKeyStatus();

  /// Check if keys already exist on this device.
  /// Use as a guard before any key generation to prevent duplicate keys.
  Future<bool> hasExistingKeys();

  /// Clear all keys from storage and memory.
  /// Call during logout or account reset.
  Future<void> clearKeys();

  // ─────────────────────────────────────────────────────────────────────────────
  // Account Creation
  // ─────────────────────────────────────────────────────────────────────────────

  /// Generate all keys for a new account.
  ///
  /// Creates:
  /// - Ultimate key (4096-bit) → held in memory only, retrieve via getUltimateKeyOnce()
  /// - Device key (3072-bit) → stored in secure storage
  /// - Symmetric key (AES-256) → stored in secure storage
  ///
  /// After calling this, you MUST retrieve the ultimate key via getUltimateKeyJwkOnce()
  /// and show it to the user for backup. It cannot be retrieved again.
  Future<void> generateAccountKeys();

  // ─────────────────────────────────────────────────────────────────────────────
  // Symmetric Data Key (AES-256-GCM) - Persisted
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get symmetric key as webcrypto object for encryption operations.
  /// Returns: AesGcmSecretKey or null if not initialized.
  Future<AesGcmSecretKey?> getSymmetricDataKey();

  /// Get symmetric key as JWK JSON string for storage/transfer.
  /// Returns: JWK JSON string or null if not initialized.
  /// Format: {"kty":"oct","k":"&lt;base64-key&gt;","alg":"A256GCM"}
  Future<String?> getSymmetricDataKeyJwk();

  // ─────────────────────────────────────────────────────────────────────────────
  // Device Key (KeyDuo) - PRIVATE - Persisted
  // ⚠️ Contains private key material - handle with care!
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get device keypair as webcrypto KeyDuo for crypto operations.
  /// Returns: KeyDuo (signing + encryption pairs) or null if not initialized.
  /// ⚠️ Contains private keys!
  Future<KeyDuo?> getDeviceKey();

  /// Get device keypair as JWK Set JSON string.
  /// Returns: JWK Set JSON with both signing and encryption private keys.
  /// ⚠️ Contains private keys!
  Future<String?> getDeviceKeyJwk();

  // ─────────────────────────────────────────────────────────────────────────────
  // Device Key - PUBLIC - Persisted
  // Safe to share - no private material
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get device encryption public key as webcrypto object.
  /// Returns: EcdhPublicKey for encrypting data TO this device.
  Future<EcdhPublicKey?> getDevicePublicKey();

  /// Get device public keys as JWK Set JSON string.
  /// Returns: JWK Set JSON with public keys only (signing + encryption).
  Future<String?> getDevicePublicKeyJwk();

  /// Get device signing public key as 128-char hex string.
  /// Returns: ECDSA P-256 public key (x + y coordinates, no 04 prefix).
  /// Use case: Bearer token identifier for auth headers.
  Future<String?> getDeviceSigningPublicKeyHex();

  // ─────────────────────────────────────────────────────────────────────────────
  // Ultimate Key (KeyDuo) - PRIVATE - In-Memory Only
  // ⚠️ ONE-TIME RETRIEVAL - Key is wiped from memory after!
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get ultimate keypair as JWK Set JSON string (ONE-TIME).
  /// Returns: JWK Set JSON with private keys, or null if not available.
  /// ⚠️ WIPES KEY FROM MEMORY after retrieval - cannot be called again!
  /// Use case: Show to user for backup during account creation.
  Future<String?> getUltimateKeyJwkOnce();

  // ─────────────────────────────────────────────────────────────────────────────
  // Ultimate Key - PUBLIC - In-Memory Only (available until private key retrieved)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get ultimate encryption public key as webcrypto object.
  /// Returns: EcdhPublicKey or null if ultimate key not in memory.
  /// Note: Returns null after getUltimateKeyJwkOnce() is called (key wiped).
  /// Use case: Encrypt recovery blob for this account.
  Future<EcdhPublicKey?> getUltimatePublicKey();

  /// Get ultimate public keys as JWK Set JSON string.
  /// Returns: JWK Set JSON with public keys only, or null if not in memory.
  /// Note: Returns null after getUltimateKeyJwkOnce() is called (key wiped).
  /// Use case: Store on server for recovery operations.
  Future<String?> getUltimatePublicKeyJwk();

  /// Get ultimate signing public key as 128-char hex string.
  /// Returns: ECDSA P-256 public key (x + y coordinates, no 04 prefix).
  /// Note: Cached after first retrieval - survives getUltimateKeyJwkOnce() wipe.
  /// Use case: Account identifier for server lookup.
  Future<String?> getUltimateSigningPublicKeyHex();

  /// Sign data with the ultimate key (while it's still in memory).
  /// Returns: Signature bytes, or null if ultimate key not in memory.
  /// Note: Returns null after getUltimateKeyJwkOnce() is called (key wiped).
  /// Use case: Sign registration payload to prove key ownership.
  Future<Uint8List?> signWithUltimateKey(Uint8List data);

  // ─────────────────────────────────────────────────────────────────────────────
  // Storage (for recovery flow)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Store a device key (JWK Set with private keys) in secure storage.
  /// Use case: Recovery flow after decrypting device key blob.
  Future<void> storeDeviceKeyJwk(String jwk);

  /// Store a symmetric data key in secure storage.
  /// Input: JWK JSON string (format: {"kty":"oct","k":"...","alg":"A256GCM"}).
  /// Use case: Recovery flow after decrypting symmetric key blob.
  Future<void> storeSymmetricDataKeyJwk(String jwk);

  // ─────────────────────────────────────────────────────────────────────────────
  // Combined Generation + Storage (for recovery flow)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Generate a new device key and store it in secure storage.
  /// Use case: Recovery flow - generate fresh device keys for the recovered account.
  Future<void> generateAndStoreDeviceKey();

  // ─────────────────────────────────────────────────────────────────────────────
  // Generation (standalone - does NOT store)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Generate a new ultimate keypair (4096-bit RSA + ECDSA P-256).
  /// Returns: KeyDuo webcrypto object.
  /// Note: Does NOT store - caller must handle the key.
  Future<KeyDuo> generateUltimateKey();

  /// Generate a new device keypair (3072-bit RSA + ECDSA P-256).
  /// Returns: KeyDuo webcrypto object.
  /// Note: Does NOT store - caller must handle the key.
  Future<KeyDuo> generateDeviceKey();

  /// Generate a new symmetric data key (AES-256).
  /// Returns: JWK JSON string.
  /// Note: Does NOT store - caller must handle the key.
  Future<String> generateSymmetricKeyJwk();

  // ─────────────────────────────────────────────────────────────────────────────
  // Import/Validate (for recovery flow)
  // ─────────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────────
  // Cross-Device Key (iCloud Keychain / Google Block Store)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Whether cross-device key storage is available on this platform.
  bool get isCrossDeviceStorageAvailable;

  /// The label used for the cross-device key device entry (e.g. "iCloud").
  String get crossDeviceLabel;

  /// Generate a new cross-device key and store in platform storage.
  /// Returns: KeyDuo webcrypto object.
  Future<KeyDuo> generateCrossDeviceKey();

  /// Retrieve cross-device key from platform storage.
  /// Returns: KeyDuo or null if not found.
  Future<KeyDuo?> getCrossDeviceKey();

  /// Delete cross-device key from platform storage.
  Future<void> deleteCrossDeviceKey();

  // ─────────────────────────────────────────────────────────────────────────────
  // Import/Validate (for recovery flow)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Import ultimate key from JWK Set JSON and hold in memory.
  /// Input: JWK Set JSON string with private keys.
  /// Returns: KeyDuo webcrypto object.
  /// Use case: User enters recovery key during account recovery.
  /// Note: After import, getUltimateKeyOnce() will return null (already "retrieved").
  Future<KeyDuo> importUltimateKeyJwk(String jwk);

  /// Validate ultimate key JWK format without importing.
  /// Input: JWK Set JSON string.
  /// Throws: ValidationException if format is invalid.
  /// Use case: Validate user input before attempting recovery.
  Future<void> validateUltimateKeyJwk(String jwk);
}


// ═══════════════════════════════════════════════════════════════════════════════
// Implementation
// ═══════════════════════════════════════════════════════════════════════════════

@LazySingleton(as: ICryptoKeyRepository)
class CryptoKeyRepository implements ICryptoKeyRepository {
  final ISecureStorage _secureStorage;
  final ICrossDeviceKeyStorage _crossDeviceStorage;

  CryptoKeyRepository(this._secureStorage, this._crossDeviceStorage);

  // In-memory storage for ultimate key (temporary, during account creation)
  // Wiped after getUltimateKeyJwkOnce() is called
  KeyDuo? _ultimateKey;
  
  // Cached ultimate public key hex (persisted for convenience)
  // This is just the public key, safe to store
  String? _ultimatePublicKeyHexCache;

  // ─────────────────────────────────────────────────────────────────────────────
  // Status
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<CryptoKeyStatus> getKeyStatus() {
    return tryMethod(
      () async {
        final deviceKey = await _secureStorage.getDeviceKey();
        final dataKey = await _secureStorage.getSymmetricDataKey();

        if (deviceKey == null || dataKey == null) {
          // No local keys — check if cross-device key is available
          if (_crossDeviceStorage.isAvailable) {
            final crossDeviceKey = await _crossDeviceStorage.retrieve();
            if (crossDeviceKey != null) {
              return CryptoKeyStatus.crossDeviceRecoveryAvailable;
            }
          }
          return CryptoKeyStatus.notInitialized;
        }
        return CryptoKeyStatus.ready;
      },
      KeyRetrievalException.new,
      'getKeyStatus',
    );
  }

  @override
  Future<void> clearKeys() {
    return tryMethod(
      () async {
        CryptoLogger.logSecurityEvent('Clearing all keys from storage and memory');
        _ultimateKey = null;
        _ultimatePublicKeyHexCache = null;
        await _secureStorage.clearAllKeys();
        // Also delete cross-device key if available
        if (_crossDeviceStorage.isAvailable) {
          await _crossDeviceStorage.delete();
        }
      },
      KeyStorageException.new,
      'clearKeys',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Account Creation
  // ─────────────────────────────────────────────────────────────────────────────

  /// Check if keys already exist on this device.
  /// Use as a guard before any key generation to prevent duplicate keys.
  @override
  Future<bool> hasExistingKeys() async {
    final status = await getKeyStatus();
    return status == CryptoKeyStatus.ready;
  }

  @override
  Future<void> generateAccountKeys() {
    return tryMethod(
      () async {
        // Defensive check: prevent duplicate key generation
        if (await hasExistingKeys()) {
          CryptoLogger.logSecurityEvent('BLOCKED: Attempted to generate keys when keys already exist');
          throw const KeyGenerationException(
            'Keys already exist on this device. Cannot generate new keys.',
            kind: KeyGenerationFailure.keysAlreadyExist,
          );
        }
        
        CryptoLogger.logOperationStart('generateAccountKeys');

        // 1. Generate Ultimate Key (ECDH P-256) - hold in memory only
        CryptoLogger.logOperationStart('generateUltimateKey (ECDH P-256)');
        _ultimateKey = await generateUltimateKey();
        
        // Verify ultimate key works (sign/verify + encrypt/decrypt roundtrips)
        final ultimateKey = _ultimateKey;
        if (ultimateKey == null) {
          throw const KeyGenerationException('Ultimate key generation returned null', kind: KeyGenerationFailure.verificationFailed);
        }
        
        // Test signing roundtrip
        final testData = Uint8List.fromList('verify-ultimate-key'.codeUnits);
        final signature = await ultimateKey.sign(testData);
        final signatureValid = await ultimateKey.verifySignature(testData, signature);
        if (!signatureValid) {
          throw const KeyGenerationException('Ultimate key signature verification failed', kind: KeyGenerationFailure.verificationFailed);
        }
        
        // Test encryption roundtrip
        final encrypted = await ultimateKey.encrypt(testData);
        final decrypted = await ultimateKey.decrypt(encrypted);
        if (testData.length != decrypted.length) {
          throw const KeyGenerationException('Ultimate key encryption verification failed: length mismatch', kind: KeyGenerationFailure.verificationFailed);
        }
        for (int i = 0; i < testData.length; i++) {
          if (testData[i] != decrypted[i]) {
            throw const KeyGenerationException('Ultimate key encryption verification failed: data mismatch', kind: KeyGenerationFailure.verificationFailed);
          }
        }
        CryptoLogger.logSuccess('ultimateKey verified');
        
        // Cache ultimate public key hex (safe to store - just public key)
        // This allows getUltimateSigningPublicKeyHex() to work even after getUltimateKeyJwkOnce() wipes the key
        _ultimatePublicKeyHexCache = await ultimateKey.signingKeyPair.exportPublicKeyHex();
        CryptoLogger.logSuccess('ultimatePublicKeyHex cached');

        // 2. Generate Device Key (ECDH P-256) - store in secure storage
        CryptoLogger.logOperationStart('generateDeviceKey (ECDH P-256)');
        final deviceKey = await generateDeviceKey();
        
        // Verify device key works
        final deviceTestData = Uint8List.fromList('verify-device-key'.codeUnits);
        final deviceSignature = await deviceKey.sign(deviceTestData);
        final deviceSignatureValid = await deviceKey.verifySignature(deviceTestData, deviceSignature);
        if (!deviceSignatureValid) {
          throw const KeyGenerationException('Device key signature verification failed', kind: KeyGenerationFailure.verificationFailed);
        }

        final deviceEncrypted = await deviceKey.encrypt(deviceTestData);
        final deviceDecrypted = await deviceKey.decrypt(deviceEncrypted);
        if (deviceTestData.length != deviceDecrypted.length) {
          throw const KeyGenerationException('Device key encryption verification failed: length mismatch', kind: KeyGenerationFailure.verificationFailed);
        }
        for (int i = 0; i < deviceTestData.length; i++) {
          if (deviceTestData[i] != deviceDecrypted[i]) {
            throw const KeyGenerationException('Device key encryption verification failed: data mismatch', kind: KeyGenerationFailure.verificationFailed);
          }
        }
        CryptoLogger.logSuccess('deviceKey verified');
        
        final serializer = KeyDuoSerializer();
        final deviceKeyJwk = await serializer.exportKeyDuo(deviceKey);
        await storeDeviceKeyJwk(deviceKeyJwk);

        // 3. Generate Symmetric Key (AES-256) - store in secure storage
        CryptoLogger.logOperationStart('generateSymmetricKey (AES-256)');
        final symmetricKeyJwk = await generateSymmetricKeyJwk();
        
        // Verify symmetric key by doing a roundtrip
        await _verifySymmetricKey(symmetricKeyJwk);
        CryptoLogger.logSuccess('symmetricKey verified');
        
        await storeSymmetricDataKeyJwk(symmetricKeyJwk);

        CryptoLogger.logSuccess('generateAccountKeys');
        CryptoLogger.logSecurityEvent('Ultimate key held in memory - must retrieve via getUltimateKeyJwkOnce()');
      },
      (message, [cause]) => KeyGenerationException(message, cause: cause),
      'generateAccountKeys',
    );
  }
  
  /// Verifies symmetric key by doing an encrypt/decrypt roundtrip.
  Future<void> _verifySymmetricKey(String jwk) async {
    final jwkMap = jsonDecode(jwk) as Map<String, dynamic>;
    final base64Key = jwkMap['k'] as String;
    final keyBytes = _decodeBase64UrlOrStandard(base64Key);
    final aesKey = await AesGcmSecretKey.importRawKey(keyBytes);
    
    // Encrypt/decrypt roundtrip test
    final testData = Uint8List.fromList('verify-symmetric-key'.codeUnits);
    final iv = Uint8List(12); // Zero IV is fine for verification
    final encrypted = await aesKey.encryptBytes(testData, iv);
    final decrypted = await aesKey.decryptBytes(encrypted, iv);
    
    if (testData.length != decrypted.length) {
      throw const KeyGenerationException('Symmetric key verification failed: length mismatch', kind: KeyGenerationFailure.verificationFailed);
    }
    for (int i = 0; i < testData.length; i++) {
      if (testData[i] != decrypted[i]) {
        throw const KeyGenerationException('Symmetric key verification failed: data mismatch', kind: KeyGenerationFailure.verificationFailed);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Getters - Symmetric
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<AesGcmSecretKey?> getSymmetricDataKey() {
    return tryMethod(
      () async {
        final jwk = await _secureStorage.getSymmetricDataKey();
        if (jwk == null) return null;
        
        // Parse JWK and import key
        // Note: JWK uses base64url encoding (handle both for compatibility)
        final jwkMap = jsonDecode(jwk) as Map<String, dynamic>;
        final base64Key = jwkMap['k'] as String;
        final keyBytes = _decodeBase64UrlOrStandard(base64Key);
        return await AesGcmSecretKey.importRawKey(keyBytes);
      },
      KeyRetrievalException.new,
      'getSymmetricDataKey',
    );
  }

  @override
  Future<String?> getSymmetricDataKeyJwk() {
    return tryMethod(
      () async {
        return await _secureStorage.getSymmetricDataKey();
      },
      KeyRetrievalException.new,
      'getSymmetricDataKeyJwk',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Getters - Device PRIVATE
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<KeyDuo?> getDeviceKey() {
    return tryMethod(
      () async {
        final jwk = await _secureStorage.getDeviceKey();
        if (jwk == null) {
          return null;
        }

        final serializer = KeyDuoSerializer();
        final keyDuo = await serializer.importKeyDuo(jwk);
        return keyDuo;
      },
      KeyRetrievalException.new,
      'getDeviceKey',
    );
  }

  @override
  Future<String?> getDeviceKeyJwk() {
    return tryMethod(
      () async {
        return await _secureStorage.getDeviceKey();
      },
      KeyRetrievalException.new,
      'getDeviceKeyJwk',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Getters - Device PUBLIC
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<EcdhPublicKey?> getDevicePublicKey() {
    return tryMethod(
      () async {
        final keyDuo = await getDeviceKey();
        return keyDuo?.encryption.publicKey;
      },
      KeyRetrievalException.new,
      'getDevicePublicKey',
    );
  }

  @override
  Future<String?> getDevicePublicKeyJwk() {
    return tryMethod(
      () async {
        final keyDuo = await getDeviceKey();
        if (keyDuo == null) return null;

        final serializer = KeyDuoSerializer();
        return await serializer.exportPublicKeyDuo(keyDuo);
      },
      KeyRetrievalException.new,
      'getDevicePublicKeyJwk',
    );
  }

  @override
  Future<String?> getDeviceSigningPublicKeyHex() {
    return tryMethod(
      () async {
        final keyDuo = await getDeviceKey();
        if (keyDuo == null) return null;
        // Export ECDSA P-256 signing public key as 128-char hex
        // (64 bytes = x + y coordinates, no 04 prefix)
        return await keyDuo.signingKeyPair.exportPublicKeyHex();
      },
      KeyRetrievalException.new,
      'getDeviceSigningPublicKeyHex',
    );
  }


  // ─────────────────────────────────────────────────────────────────────────────
  // Getters - Ultimate PRIVATE (one-time, wipes from memory)
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<String?> getUltimateKeyJwkOnce() {
    return tryMethod(
      () async {
        final ultimateKey = _ultimateKey;
        if (ultimateKey == null) {
          CryptoLogger.logSecurityEvent('Ultimate key not available (already wiped or never generated)');
          return null;
        }

        final serializer = KeyDuoSerializer();
        final jwk = await serializer.exportKeyDuo(ultimateKey);
        
        // WIPE from memory - this is the one-time retrieval
        _ultimateKey = null;
        
        CryptoLogger.logSecurityEvent('Ultimate key JWK retrieved and WIPED from memory');
        return jwk;
      },
      KeyRetrievalException.new,
      'getUltimateKeyJwkOnce',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Getters - Ultimate PUBLIC (available until private key retrieved)
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<EcdhPublicKey?> getUltimatePublicKey() {
    return tryMethod(
      () async {
        return _ultimateKey?.encryption.publicKey;
      },
      KeyRetrievalException.new,
      'getUltimatePublicKey',
    );
  }

  @override
  Future<String?> getUltimatePublicKeyJwk() {
    return tryMethod(
      () async {
        final ultimateKey = _ultimateKey;
        if (ultimateKey == null) return null;

        final serializer = KeyDuoSerializer();
        return await serializer.exportPublicKeyDuo(ultimateKey);
      },
      KeyRetrievalException.new,
      'getUltimatePublicKeyJwk',
    );
  }

  @override
  Future<String?> getUltimateSigningPublicKeyHex() {
    return tryMethod(
      () async {
        // Return cached value if available (survives getUltimateKeyJwkOnce() wipe)
        if (_ultimatePublicKeyHexCache != null) {
          return _ultimatePublicKeyHexCache;
        }
        
        // Fall back to deriving from in-memory key if cache not set
        final ultimateKey = _ultimateKey;
        if (ultimateKey == null) return null;

        // Export ECDSA P-256 signing public key as 128-char hex
        // (64 bytes = x + y coordinates, no 04 prefix)
        final hex = await ultimateKey.signingKeyPair.exportPublicKeyHex();
        _ultimatePublicKeyHexCache = hex; // Cache it
        return hex;
      },
      KeyRetrievalException.new,
      'getUltimateSigningPublicKeyHex',
    );
  }

  @override
  Future<Uint8List?> signWithUltimateKey(Uint8List data) {
    return tryMethod(
      () async {
        final ultimateKey = _ultimateKey;
        if (ultimateKey == null) return null;
        
        return await ultimateKey.sign(data);
      },
      KeyRetrievalException.new,
      'signWithUltimateKey',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Storage
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<void> storeDeviceKeyJwk(String jwk) {
    return tryMethod(
      () async {
        await _secureStorage.storeDeviceKey(jwk);
        CryptoLogger.logSuccess('storeDeviceKeyJwk');
      },
      KeyStorageException.new,
      'storeDeviceKeyJwk',
    );
  }

  @override
  Future<void> storeSymmetricDataKeyJwk(String jwk) {
    return tryMethod(
      () async {
        // Validate JWK format before storing
        _validateSymmetricKeyJwk(jwk);
        await _secureStorage.storeSymmetricDataKey(jwk);
        CryptoLogger.logSuccess('storeSymmetricDataKeyJwk');
      },
      KeyStorageException.new,
      'storeSymmetricDataKeyJwk',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Combined Generation + Storage
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<void> generateAndStoreDeviceKey() {
    return tryMethod(
      () async {
        CryptoLogger.logOperationStart('generateAndStoreDeviceKey');
        
        // Generate new device key (ECDH P-256)
        final deviceKey = await generateDeviceKey();
        
        // Verify device key works
        final deviceTestData = Uint8List.fromList('verify-device-key'.codeUnits);
        final deviceSignature = await deviceKey.sign(deviceTestData);
        final deviceSignatureValid = await deviceKey.verifySignature(deviceTestData, deviceSignature);
        if (!deviceSignatureValid) {
          throw const KeyGenerationException('Device key signature verification failed', kind: KeyGenerationFailure.verificationFailed);
        }

        final deviceEncrypted = await deviceKey.encrypt(deviceTestData);
        final deviceDecrypted = await deviceKey.decrypt(deviceEncrypted);
        if (deviceTestData.length != deviceDecrypted.length) {
          throw const KeyGenerationException('Device key encryption verification failed: length mismatch', kind: KeyGenerationFailure.verificationFailed);
        }
        for (int i = 0; i < deviceTestData.length; i++) {
          if (deviceTestData[i] != deviceDecrypted[i]) {
            throw const KeyGenerationException('Device key encryption verification failed: data mismatch', kind: KeyGenerationFailure.verificationFailed);
          }
        }
        CryptoLogger.logSuccess('deviceKey verified');
        
        // Store in secure storage
        final serializer = KeyDuoSerializer();
        final deviceKeyJwk = await serializer.exportKeyDuo(deviceKey);
        await storeDeviceKeyJwk(deviceKeyJwk);
        
        CryptoLogger.logSuccess('generateAndStoreDeviceKey');
      },
      (message, [cause]) => KeyGenerationException(message, cause: cause),
      'generateAndStoreDeviceKey',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cross-Device Key
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  bool get isCrossDeviceStorageAvailable => _crossDeviceStorage.isAvailable;

  @override
  String get crossDeviceLabel => _crossDeviceStorage.deviceLabel;

  @override
  Future<KeyDuo> generateCrossDeviceKey() {
    return tryMethod(
      () async {
        CryptoLogger.logOperationStart('generateCrossDeviceKey');

        final keyDuo = await GenerationService.generateKeyDuo();

        // Verify the key works
        final testData = Uint8List.fromList('verify-cross-device-key'.codeUnits);
        final signature = await keyDuo.sign(testData);
        final valid = await keyDuo.verifySignature(testData, signature);
        if (!valid) {
          throw const KeyGenerationException(
            'Cross-device key signature verification failed',
            kind: KeyGenerationFailure.verificationFailed,
          );
        }
        CryptoLogger.logSuccess('crossDeviceKey verified');

        // Export and store in platform storage
        final serializer = KeyDuoSerializer();
        final jwk = await serializer.exportKeyDuo(keyDuo);
        await _crossDeviceStorage.store(jwk);

        CryptoLogger.logSuccess('generateCrossDeviceKey (stored in ${_crossDeviceStorage.deviceLabel})');
        return keyDuo;
      },
      (message, [cause]) => KeyGenerationException(message, cause: cause),
      'generateCrossDeviceKey',
    );
  }

  @override
  Future<KeyDuo?> getCrossDeviceKey() {
    return tryMethod(
      () async {
        final jwk = await _crossDeviceStorage.retrieve();
        if (jwk == null) return null;

        final serializer = KeyDuoSerializer();
        return await serializer.importKeyDuo(jwk);
      },
      KeyRetrievalException.new,
      'getCrossDeviceKey',
    );
  }

  @override
  Future<void> deleteCrossDeviceKey() {
    return tryMethod(
      () async {
        CryptoLogger.logSecurityEvent('Deleting cross-device key (${_crossDeviceStorage.deviceLabel})');
        await _crossDeviceStorage.delete();
        CryptoLogger.logSuccess('deleteCrossDeviceKey');
      },
      KeyStorageException.new,
      'deleteCrossDeviceKey',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Validates symmetric key JWK format.
  void _validateSymmetricKeyJwk(String jwk) {
    final jwkMap = jsonDecode(jwk) as Map<String, dynamic>;
    
    // Check required fields
    if (jwkMap['kty'] != 'oct') {
      throw const ValidationException('Symmetric key must have kty="oct"');
    }
    if (!jwkMap.containsKey('k')) {
      throw const ValidationException('Symmetric key must contain "k" field');
    }
    
    // Validate key length (AES-256 = 32 bytes)
    // Note: JWK uses base64url encoding (may or may not have padding)
    final base64Key = jwkMap['k'] as String;
    final keyBytes = _decodeBase64UrlOrStandard(base64Key);
    if (keyBytes.length != 32) {
      throw ValidationException(
        'Symmetric key must be 256 bits (32 bytes), got ${keyBytes.length} bytes',
      );
    }
  }

  /// Decodes base64url or standard base64 (handles both for compatibility).
  Uint8List _decodeBase64UrlOrStandard(String input) {
    // Normalize: add padding if missing (base64url often omits it)
    var normalized = input;
    final remainder = normalized.length % 4;
    if (remainder > 0) {
      normalized += '=' * (4 - remainder);
    }
    // Try base64url first (JWK spec), fall back to standard base64
    try {
      return base64Url.decode(normalized);
    } catch (_) {
      return base64.decode(normalized);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Generation
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<KeyDuo> generateUltimateKey() {
    return tryMethod(
      () async {
        CryptoLogger.logOperationStart('generateUltimateKey (ECDH P-256)');
        return await GenerationService.generateKeyDuo();
      },
      (message, [cause]) => KeyGenerationException(message, cause: cause),
      'generateUltimateKey',
    );
  }

  @override
  Future<KeyDuo> generateDeviceKey() {
    return tryMethod(
      () async {
        CryptoLogger.logOperationStart('generateDeviceKey (ECDH P-256)');
        final keyDuo = await GenerationService.generateKeyDuo();
        return keyDuo;
      },
      (message, [cause]) => KeyGenerationException(message, cause: cause),
      'generateDeviceKey',
    );
  }

  @override
  Future<String> generateSymmetricKeyJwk() {
    return tryMethod(
      () async {
        // Generate AES-256 key using webcrypto
        final aesKey = await AesGcmSecretKey.generateKey(256);
        final aesKeyBytes = await aesKey.exportRawKey();
        // Return as JWK JSON (RFC 7517 format for symmetric keys)
        // Note: JWK spec requires base64url encoding WITHOUT padding
        return jsonEncode({
          'kty': 'oct',                                            // Key type: octet sequence
          'k': base64Url.encode(aesKeyBytes).replaceAll('=', ''),  // Key value (base64url, no padding)
          'alg': 'A256GCM',                                        // Algorithm: AES-256-GCM
        });
      },
      (message, [cause]) => KeyGenerationException(message, cause: cause),
      'generateSymmetricKeyJwk',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Import/Validate
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Future<KeyDuo> importUltimateKeyJwk(String jwk) {
    return tryMethod(
      () async {
        // Parse, validate, and verify JWK via cryptographic roundtrips
        final serializer = KeyDuoSerializer();
        final keyDuo = await serializer.importKeyDuo(jwk);
        
        // Store in memory temporarily for recovery operations (decrypt blob, etc.)
        // Note: We don't need getUltimateKeyJwkOnce() after import since user already has the key
        _ultimateKey = keyDuo;
        
        CryptoLogger.logSuccess('importUltimateKeyJwk (verified and held in memory for recovery ops)');
        return keyDuo;
      },
      KeyRetrievalException.new,
      'importUltimateKeyJwk',
    );
  }

  @override
  Future<void> validateUltimateKeyJwk(String jwk) {
    return tryMethod(
      () async {
        // Check for empty input
        if (jwk.trim().isEmpty) {
          throw const ValidationException('Ultimate key cannot be empty');
        }
        // Full verification: parse, validate structure, and run crypto roundtrips
        final serializer = KeyDuoSerializer();
        await serializer.importKeyDuo(jwk);
        // Verification passed - do NOT store the key
        CryptoLogger.logSuccess('validateUltimateKeyJwk (verified via crypto roundtrips)');
      },
      ValidationException.new,
      'validateUltimateKeyJwk',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────────
}
