import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:quanitya_flutter/infrastructure/crypto/crypto_key_repository.dart';
import 'package:quanitya_flutter/infrastructure/crypto/interfaces/i_secure_storage.dart';
import 'package:quanitya_flutter/infrastructure/crypto/interfaces/i_cross_device_key_storage.dart';

@GenerateMocks([ISecureStorage, ICrossDeviceKeyStorage])
import 'cross_device_key_status_test.mocks.dart';

/// Tests for CryptoKeyRepository cross-device key detection logic.
///
/// Focuses on:
/// - getKeyStatus() returning crossDeviceRecoveryAvailable when appropriate
/// - clearKeys() also clearing cross-device key
void main() {
  late MockISecureStorage mockSecureStorage;
  late MockICrossDeviceKeyStorage mockCrossDeviceStorage;
  late CryptoKeyRepository keyRepo;

  setUp(() {
    mockSecureStorage = MockISecureStorage();
    mockCrossDeviceStorage = MockICrossDeviceKeyStorage();
    keyRepo = CryptoKeyRepository(mockSecureStorage, mockCrossDeviceStorage);
  });

  group('getKeyStatus — cross-device detection', () {
    test('returns crossDeviceRecoveryAvailable when no local keys but cross-device key exists', () async {
      // No local keys
      when(mockSecureStorage.getDeviceKey()).thenAnswer((_) async => null);
      when(mockSecureStorage.getSymmetricDataKey()).thenAnswer((_) async => null);

      // Cross-device storage is available and has a key
      when(mockCrossDeviceStorage.isAvailable).thenReturn(true);
      when(mockCrossDeviceStorage.retrieve()).thenAnswer((_) async => '{"kty":"EC"}');

      final status = await keyRepo.getKeyStatus();

      expect(status, equals(CryptoKeyStatus.crossDeviceRecoveryAvailable));
      verify(mockCrossDeviceStorage.retrieve()).called(1);
    });

    test('returns notInitialized when no local keys and no cross-device key', () async {
      when(mockSecureStorage.getDeviceKey()).thenAnswer((_) async => null);
      when(mockSecureStorage.getSymmetricDataKey()).thenAnswer((_) async => null);

      when(mockCrossDeviceStorage.isAvailable).thenReturn(true);
      when(mockCrossDeviceStorage.retrieve()).thenAnswer((_) async => null);

      final status = await keyRepo.getKeyStatus();

      expect(status, equals(CryptoKeyStatus.notInitialized));
    });

    test('returns notInitialized when no local keys and cross-device storage unavailable', () async {
      when(mockSecureStorage.getDeviceKey()).thenAnswer((_) async => null);
      when(mockSecureStorage.getSymmetricDataKey()).thenAnswer((_) async => null);

      when(mockCrossDeviceStorage.isAvailable).thenReturn(false);

      final status = await keyRepo.getKeyStatus();

      expect(status, equals(CryptoKeyStatus.notInitialized));
      verifyNever(mockCrossDeviceStorage.retrieve());
    });

    test('returns ready when local keys exist (skips cross-device check)', () async {
      when(mockSecureStorage.getDeviceKey()).thenAnswer((_) async => '{"keys":[]}');
      when(mockSecureStorage.getSymmetricDataKey()).thenAnswer((_) async => '{"kty":"oct"}');

      final status = await keyRepo.getKeyStatus();

      expect(status, equals(CryptoKeyStatus.ready));
      verifyNever(mockCrossDeviceStorage.retrieve());
    });
  });

  group('clearKeys — cross-device cleanup', () {
    test('deletes cross-device key when storage is available', () async {
      when(mockSecureStorage.clearAllKeys()).thenAnswer((_) async {});
      when(mockCrossDeviceStorage.isAvailable).thenReturn(true);
      when(mockCrossDeviceStorage.delete()).thenAnswer((_) async {});

      await keyRepo.clearKeys();

      verify(mockSecureStorage.clearAllKeys()).called(1);
      verify(mockCrossDeviceStorage.delete()).called(1);
    });

    test('skips cross-device deletion when storage is unavailable', () async {
      when(mockSecureStorage.clearAllKeys()).thenAnswer((_) async {});
      when(mockCrossDeviceStorage.isAvailable).thenReturn(false);

      await keyRepo.clearKeys();

      verify(mockSecureStorage.clearAllKeys()).called(1);
      verifyNever(mockCrossDeviceStorage.delete());
    });
  });

  group('cross-device storage properties', () {
    test('isCrossDeviceStorageAvailable delegates to storage', () {
      when(mockCrossDeviceStorage.isAvailable).thenReturn(true);
      expect(keyRepo.isCrossDeviceStorageAvailable, isTrue);

      when(mockCrossDeviceStorage.isAvailable).thenReturn(false);
      expect(keyRepo.isCrossDeviceStorageAvailable, isFalse);
    });

    test('crossDeviceLabel delegates to storage', () {
      when(mockCrossDeviceStorage.deviceLabel).thenReturn('iCloud');
      expect(keyRepo.crossDeviceLabel, equals('iCloud'));

      when(mockCrossDeviceStorage.deviceLabel).thenReturn('Google Backup');
      expect(keyRepo.crossDeviceLabel, equals('Google Backup'));
    });
  });
}
