import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webcrypto/webcrypto.dart';
import 'package:injectable/injectable.dart';
import 'package:dart_jwk_duo/dart_jwk_duo.dart';

import '../core/try_operation.dart';
import 'crypto_key_repository.dart';
import 'exceptions/crypto_exceptions.dart';

/// Thrown when encryption is attempted but no symmetric data key has been provisioned.
class SymmetricKeyNotProvisionedException implements Exception {
  const SymmetricKeyNotProvisionedException([this.message = 'Symmetric data key not provisioned. Complete device onboarding first.']);
  
  final String message;
  final Object? cause = null;
  
  @override
  String toString() => 'SymmetricKeyNotProvisionedException: $message';
}

/// Thrown when device key operations are attempted but no device key exists.
class DeviceKeyNotProvisionedException implements Exception {
  const DeviceKeyNotProvisionedException([this.message = 'Device key not provisioned. Complete device onboarding first.']);
  
  final String message;
  final Object? cause = null;
  
  @override
  String toString() => 'DeviceKeyNotProvisionedException: $message';
}

/// Interface for all cryptographic operations.
abstract class IDataEncryptionService {
  Future<bool> isKeyProvisioned();
  Future<Uint8List> encryptData(String plaintext);
  Future<String> decryptData(Uint8List ciphertext);
  Future<Uint8List> encryptWithDeviceKey(Uint8List data);
  Future<Uint8List> decryptWithDeviceKey(Uint8List ciphertext);
  Future<String> signWithDeviceKey(String challenge);
  Future<bool> verifyWithDeviceKey(String challenge, String signatureHex);
  Future<String> createEncryptedBlob(String symmetricKeyJwk, EcdhPublicKey publicKey);
  Future<String> decryptBlob(String blob, EcdhPrivateKey privateKey);
  Future<Uint8List> encryptWithPublicKey(Uint8List data, EcdhPublicKey publicKey);
  Future<String> signWithKeyDuo(String data, KeyDuo keyDuo);
}

@Injectable(as: IDataEncryptionService)
class DataEncryptionService implements IDataEncryptionService {
  final ICryptoKeyRepository _keyRepository;

  DataEncryptionService(this._keyRepository);
  
  @override
  Future<bool> isKeyProvisioned() {
    return tryMethod(
      () async {
        final key = await _keyRepository.getSymmetricDataKey();
        return key != null;
      },
      CryptoOperationException.new,
      'isKeyProvisioned',
    );
  }


  @override
  Future<Uint8List> encryptData(String plaintext) {
    return tryMethod(
      () async {
        final secretKey = await _getSymmetricKey();
        final plaintextBytes = utf8.encode(plaintext);
        
        final iv = Uint8List(12);
        fillRandomBytes(iv);
        
        final ciphertext = await secretKey.encryptBytes(plaintextBytes, iv);
        
        final result = Uint8List(iv.length + ciphertext.length);
        result.setRange(0, iv.length, iv);
        result.setRange(iv.length, result.length, ciphertext);
        
        return result;
      },
      CryptoOperationException.new,
      'encryptData',
    );
  }

  @override
  Future<String> decryptData(Uint8List ciphertext) {
    return tryMethod(
      () async {
        final secretKey = await _getSymmetricKey();
        
        if (ciphertext.length < 12) {
          throw const CryptoOperationException('Ciphertext too short to contain IV');
        }
        
        final iv = ciphertext.sublist(0, 12);
        final encryptedData = ciphertext.sublist(12);
        
        final plaintextBytes = await secretKey.decryptBytes(encryptedData, iv);
        
        return utf8.decode(plaintextBytes);
      },
      CryptoOperationException.new,
      'decryptData',
    );
  }

  @override
  Future<Uint8List> encryptWithDeviceKey(Uint8List data) {
    return tryMethod(
      () async {
        final keyDuo = await _getDeviceKeyDuo();
        return await keyDuo.encrypt(data);
      },
      CryptoOperationException.new,
      'encryptWithDeviceKey',
    );
  }

  @override
  Future<Uint8List> decryptWithDeviceKey(Uint8List ciphertext) {
    return tryMethod(
      () async {
        final keyDuo = await _getDeviceKeyDuo();
        return await keyDuo.decrypt(ciphertext);
      },
      CryptoOperationException.new,
      'decryptWithDeviceKey',
    );
  }

  @override
  Future<String> signWithDeviceKey(String challenge) {
    return tryMethod(
      () async {
        final keyDuo = await _getDeviceKeyDuo();
        final challengeBytes = utf8.encode(challenge);
        final signatureBytes = await keyDuo.signingKeyPair.signBytes(Uint8List.fromList(challengeBytes));
        
        final hexSignature = signatureBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        
        return hexSignature;
      },
      CryptoOperationException.new,
      'signWithDeviceKey',
    );
  }

  @override
  Future<bool> verifyWithDeviceKey(String challenge, String signatureHex) {
    return tryMethod(
      () async {
        final keyDuo = await _getDeviceKeyDuo();
        final challengeBytes = utf8.encode(challenge);
        
        final signatureBytes = Uint8List(signatureHex.length ~/ 2);
        for (int i = 0; i < signatureBytes.length; i++) {
          signatureBytes[i] = int.parse(signatureHex.substring(i * 2, i * 2 + 2), radix: 16);
        }
        
        return await keyDuo.signingKeyPair.verifyBytes(
          Uint8List.fromList(challengeBytes),
          signatureBytes,
        );
      },
      CryptoOperationException.new,
      'verifyWithDeviceKey',
    );
  }

  @override
  Future<String> createEncryptedBlob(String symmetricKeyJwk, EcdhPublicKey publicKey) {
    return tryMethod(
      () async {
        final jwkBytes = utf8.encode(symmetricKeyJwk);
        
        // Use CryptoService directly with a temporary KeyDuo
        // We need a dummy signing key since CryptoService expects a full KeyDuo
        final dummySigningKeyPair = await EcdsaPrivateKey.generateKey(EllipticCurve.p256);
        final tempKeyDuo = KeyDuo(
          signing: SigningKeyPair(
            privateKey: dummySigningKeyPair.privateKey,
            publicKey: dummySigningKeyPair.publicKey,
          ),
          encryption: EncryptionKeyPair.publicOnly(publicKey: publicKey),
        );
        
        final encryptedBytes = await CryptoService.encrypt(Uint8List.fromList(jwkBytes), tempKeyDuo);
        return base64.encode(encryptedBytes);
      },
      CryptoOperationException.new,
      'createEncryptedBlob',
    );
  }

  @override
  Future<String> decryptBlob(String blob, EcdhPrivateKey privateKey) {
    return tryMethod(
      () async {
        final blobBytes = base64.decode(blob);
        
        // Use CryptoService directly with a temporary KeyDuo
        // We need a dummy signing key since CryptoService expects a full KeyDuo
        final dummySigningKeyPair = await EcdsaPrivateKey.generateKey(EllipticCurve.p256);
        
        // Generate the corresponding public key for the private key
        final publicKeyPair = await EcdhPrivateKey.generateKey(EllipticCurve.p256);
        final tempKeyDuo = KeyDuo(
          signing: SigningKeyPair(
            privateKey: dummySigningKeyPair.privateKey,
            publicKey: dummySigningKeyPair.publicKey,
          ),
          encryption: EncryptionKeyPair(privateKey: privateKey, publicKey: publicKeyPair.publicKey),
        );
        
        final decryptedBytes = await CryptoService.decrypt(blobBytes, tempKeyDuo);
        return utf8.decode(decryptedBytes);
      },
      CryptoOperationException.new,
      'decryptBlob',
    );
  }

  @override
  Future<Uint8List> encryptWithPublicKey(Uint8List data, EcdhPublicKey publicKey) {
    return tryMethod(
      () async {
        // Use CryptoService directly with a temporary KeyDuo
        // We need a dummy signing key since CryptoService expects a full KeyDuo
        final dummySigningKeyPair = await EcdsaPrivateKey.generateKey(EllipticCurve.p256);
        final tempKeyDuo = KeyDuo(
          signing: SigningKeyPair(
            privateKey: dummySigningKeyPair.privateKey,
            publicKey: dummySigningKeyPair.publicKey,
          ),
          encryption: EncryptionKeyPair.publicOnly(publicKey: publicKey),
        );
        
        return await CryptoService.encrypt(data, tempKeyDuo);
      },
      CryptoOperationException.new,
      'encryptWithPublicKey',
    );
  }

  @override
  Future<String> signWithKeyDuo(String data, KeyDuo keyDuo) {
    return tryMethod(
      () async {
        final dataBytes = utf8.encode(data);
        final signatureBytes = await keyDuo.signingKeyPair.signBytes(Uint8List.fromList(dataBytes));
        return signatureBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      },
      CryptoOperationException.new,
      'signWithKeyDuo',
    );
  }

  Future<AesGcmSecretKey> _getSymmetricKey() async {
    final secretKey = await _keyRepository.getSymmetricDataKey();
    if (secretKey == null) {
      throw const SymmetricKeyNotProvisionedException();
    }
    return secretKey;
  }

  Future<KeyDuo> _getDeviceKeyDuo() async {
    final keyDuo = await _keyRepository.getDeviceKey();
    if (keyDuo == null) {
      throw const DeviceKeyNotProvisionedException();
    }
    return keyDuo;
  }
}
