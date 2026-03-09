import 'dart:convert';

import 'package:dart_jwk_duo/dart_jwk_duo.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:webcrypto/webcrypto.dart';

import '../../../features/app_operating_mode/models/app_operating_mode.dart';
import '../../../features/app_operating_mode/repositories/app_operating_repository.dart';
import '../../../infrastructure/core/try_operation.dart';
import '../../../infrastructure/crypto/crypto_key_repository.dart';
import '../../../infrastructure/crypto/data_encryption_service.dart';
import '../models/pairing_qr_data.dart';

/// Exception for pairing-related errors.
class PairingException implements Exception {
  const PairingException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() => 'PairingException: $message';
}

/// Result of generating pairing QR data (Device B flow).
class GeneratedPairingData {
  const GeneratedPairingData({
    required this.qrData,
    required this.deviceKey,
    required this.signingKeyHex,
  });

  final PairingQrData qrData;
  final KeyDuo deviceKey;
  final String signingKeyHex;
}

/// Result of scanning pairing QR (Device A flow).
class ScannedPairingData {
  const ScannedPairingData({
    required this.label,
    required this.signingKeyHex,
    required this.encryptionPublicKey,
  });

  final String label;
  final String signingKeyHex;
  final EcdhPublicKey encryptionPublicKey;
}

/// Service for device pairing operations.
///
/// Handles the cryptographic and API operations for pairing a new device
/// to an existing account. Follows the tryMethod pattern for consistent
/// exception handling.
abstract class IPairingService {
  /// Generate QR data for Device B (new device wanting to join).
  /// Returns the QR data, generated device key, and signing key hex for polling.
  Future<GeneratedPairingData> generatePairingQrData(String deviceLabel);

  /// Parse and validate scanned QR code (Device A flow).
  /// Returns the parsed data needed for confirmation dialog.
  Future<ScannedPairingData> parseQrCode(String qrJson);

  /// Monitor registration status for our device (Device B flow).
  /// Connects to server stream and waits for registration event.
  /// Yields the encrypted data key when registered.
  Stream<String> monitorRegistration(String signingKeyHex);

  /// Complete pairing by decrypting SDK and storing keys (Device B flow).
  Future<void> completePairing({
    required String encryptedDataKey,
    required KeyDuo deviceKey,
  });

  /// Register Device B from Device A's perspective.
  /// Encrypts SDK with Device B's public key and calls server.
  Future<void> registerDevice({
    required String signingKeyHex,
    required EcdhPublicKey encryptionPublicKey,
    required String label,
  });
}

@LazySingleton(as: IPairingService)
class PairingService implements IPairingService {
  final ICryptoKeyRepository _keyRepository;
  final IDataEncryptionService _encryption;
  final Client _client;
  final AppOperatingRepository _appOperatingRepository;

  PairingService(
    this._keyRepository,
    this._encryption,
    this._client,
    this._appOperatingRepository,
  );

  @override
  Future<GeneratedPairingData> generatePairingQrData(String deviceLabel) {
    return tryMethod(
      () async {
        // Defensive check: prevent pairing if keys already exist
        if (await _keyRepository.hasExistingKeys()) {
          debugPrint(
            'PairingService: BLOCKED - Keys already exist on this device',
          );
          throw const PairingException(
            'This device is already set up. Cannot pair again.',
          );
        }

        debugPrint('PairingService: Generating device keys...');

        // 1. Generate device key (3072-bit RSA + ECDSA P-256)
        final deviceKey = await _keyRepository.generateDeviceKey();

        // 2. Export public key as JWK Set
        final serializer = KeyDuoSerializer();
        final publicKeyJwk = await serializer.exportPublicKeyDuo(deviceKey);

        // 3. Get signing public key hex (for polling)
        final signingKeyHex = await deviceKey.signingKeyPair
            .exportPublicKeyHex();

        // 4. Create QR data
        final qrData = PairingQrData(
          action: PairingAction.pair,
          devicePublicKeyJwk: publicKeyJwk,
          label: deviceLabel,
        );

        debugPrint('PairingService: QR data generated');

        return GeneratedPairingData(
          qrData: qrData,
          deviceKey: deviceKey,
          signingKeyHex: signingKeyHex,
        );
      },
      PairingException.new,
      'generatePairingQrData',
    );
  }

  @override
  Future<ScannedPairingData> parseQrCode(String qrJson) {
    return tryMethod(
      () async {
        debugPrint('PairingService: Parsing QR code...');

        // 1. Parse JSON
        final Map<String, dynamic> json;
        try {
          json = jsonDecode(qrJson) as Map<String, dynamic>;
        } catch (e) {
          throw PairingException('Invalid QR code format', e);
        }

        final qrData = PairingQrData.fromJson(json);

        // 2. Validate action
        if (qrData.action != PairingAction.pair) {
          throw const PairingException('Invalid QR code: not a pairing code');
        }

        // 3. Import Device B's public key
        final serializer = KeyDuoSerializer();
        final deviceBPublicKey = await serializer.importPublicKeyDuo(
          qrData.devicePublicKeyJwk,
        );

        // 4. Extract signing public key hex
        final signingKeyHex = await deviceBPublicKey.signingKeyPair
            .exportPublicKeyHex();

        debugPrint('PairingService: QR parsed, device label: ${qrData.label}');

        return ScannedPairingData(
          label: qrData.label,
          signingKeyHex: signingKeyHex,
          encryptionPublicKey: deviceBPublicKey.encryption.publicKey,
        );
      },
      PairingException.new,
      'parseQrCode',
    );
  }

  @override
  Stream<String> monitorRegistration(String signingKeyHex) async* {
    debugPrint('PairingService: Monitoring registration for $signingKeyHex');

    try {
      final stream = _client.modules.anonaccount.device.monitorRegistration(
        signingKeyHex,
      );

      await for (final event in stream) {
        debugPrint('PairingService: Registration event received!');
        yield event.encryptedDataKey;
      }
    } catch (e) {
      debugPrint('PairingService: Monitor error: $e');
      throw PairingException('Failed to monitor registration', e);
    }
  }

  @override
  Future<void> completePairing({
    required String encryptedDataKey,
    required KeyDuo deviceKey,
  }) {
    return tryMethod(
      () async {
        debugPrint('PairingService: Completing pairing...');

        final privateKey = deviceKey.encryption.privateKey;
        if (privateKey == null) {
          throw const PairingException('Device private key not available');
        }

        // 1. Decrypt SDK blob with our private key
        final sdkJwk = await _encryption.decryptBlob(
          encryptedDataKey,
          privateKey,
        );

        // 2. Store device key
        final serializer = KeyDuoSerializer();
        final deviceKeyJwk = await serializer.exportKeyDuo(deviceKey);
        await _keyRepository.storeDeviceKeyJwk(deviceKeyJwk);

        // 3. Store symmetric key
        await _keyRepository.storeSymmetricDataKeyJwk(sdkJwk);

        // 4. Switch app to cloud mode after successful pairing
        debugPrint(
          '🔐 PairingService: Switching app to cloud mode after pairing...',
        );
        await _appOperatingRepository.updateMode(AppOperatingMode.cloud);
        debugPrint(
          '🔐 PairingService: App switched to cloud mode successfully',
        );

        debugPrint('PairingService: Pairing completed successfully!');
      },
      PairingException.new,
      'completePairing',
    );
  }

  @override
  Future<void> registerDevice({
    required String signingKeyHex,
    required EcdhPublicKey encryptionPublicKey,
    required String label,
  }) {
    return tryMethod(
      () async {
        debugPrint('PairingService: Registering device "$label"...');
        debugPrint('PairingService:   signingKeyHex: $signingKeyHex');

        // 1. Get our symmetric key
        debugPrint('PairingService:   Step 1: Retrieving symmetric key...');
        final sdkJwk = await _keyRepository.getSymmetricDataKeyJwk();
        if (sdkJwk == null) {
          debugPrint(
            'PairingService:   ERROR: Symmetric key not available in repository',
          );
          throw const PairingException('Symmetric key not available');
        }
        debugPrint(
          'PairingService:   Symmetric key found (length: ${sdkJwk.length})',
        );

        // 2. Encrypt SDK with Device B's public key
        debugPrint(
          'PairingService:   Step 2: Encrypting SDK for new device...',
        );
        final encryptedDataKey = await _encryption.createEncryptedBlob(
          sdkJwk,
          encryptionPublicKey,
        );
        debugPrint(
          'PairingService:   SDK encrypted successfully (length: ${encryptedDataKey.length})',
        );

        // 3. Register Device B (server derives accountId from our auth)
        debugPrint(
          'PairingService:   Step 3: Calling server.registerDeviceForAccount...',
        );
        await _client.modules.anonaccount.device.registerDeviceForAccount(
          signingKeyHex,
          encryptedDataKey,
          label,
        );

        debugPrint('PairingService: Device registered successfully!');
      },
      PairingException.new,
      'registerDevice',
    );
  }
}
