import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quanitya_flutter/infrastructure/security/database_key_service.dart';

import 'database_key_service_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  group('DatabaseKeyService', () {
    late MockFlutterSecureStorage mockStorage;
    late DatabaseKeyService service;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      service = DatabaseKeyService.withStorage(mockStorage);
    });

    group('getOrCreateEncryptedAtRestKey', () {
      test('returns existing key with wasCreated=false when key already stored', () async {
        const storedKey = 'abc123existingkey';
        when(mockStorage.read(
          key: 'encryptedAtRestKey',
          iOptions: anyNamed('iOptions'),
        )).thenAnswer((_) async => storedKey);

        final result = await service.getOrCreateEncryptedAtRestKey();

        expect(result.key, equals(storedKey));
        expect(result.wasCreated, isFalse);
        verifyNever(mockStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
        ));
      });

      test('generates and stores new 64-char hex key with wasCreated=true when key absent', () async {
        when(mockStorage.read(
          key: 'encryptedAtRestKey',
          iOptions: anyNamed('iOptions'),
        )).thenAnswer((_) async => null);
        when(mockStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
        )).thenAnswer((_) async {});

        final result = await service.getOrCreateEncryptedAtRestKey();

        expect(result.wasCreated, isTrue);
        // 32 bytes = 64 hex characters
        expect(result.key.length, equals(64));
        // Only hex chars
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(result.key), isTrue);
        verify(mockStorage.write(
          key: 'encryptedAtRestKey',
          value: result.key,
          iOptions: anyNamed('iOptions'),
        )).called(1);
      });

      test('returns different keys on separate first-run calls (random generation)', () async {
        // Collision probability is 1/2^256 (32 random bytes). Non-deterministic
        // by design — this verifies Random.secure() is used, not a constant.
        when(mockStorage.read(
          key: anyNamed('key'),
          iOptions: anyNamed('iOptions'),
        )).thenAnswer((_) async => null);
        when(mockStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
        )).thenAnswer((_) async {});

        final result1 = await service.getOrCreateEncryptedAtRestKey();
        final result2 = await service.getOrCreateEncryptedAtRestKey();

        expect(result1.key, isNot(equals(result2.key)));
      });

      test('is idempotent — second call returns same key with wasCreated=false', () async {
        const key = 'somekey';
        var callCount = 0;
        when(mockStorage.read(
          key: 'encryptedAtRestKey',
          iOptions: anyNamed('iOptions'),
        )).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? null : key; // null first call, key thereafter
        });
        when(mockStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
          iOptions: anyNamed('iOptions'),
        )).thenAnswer((_) async {});

        final first = await service.getOrCreateEncryptedAtRestKey();
        final second = await service.getOrCreateEncryptedAtRestKey();

        expect(first.wasCreated, isTrue);
        expect(second.wasCreated, isFalse);
        expect(second.key, equals(key));
      });
    });

    group('deleteEncryptedAtRestKey', () {
      test('deletes key from storage', () async {
        when(mockStorage.delete(
          key: 'encryptedAtRestKey',
          iOptions: anyNamed('iOptions'),
        )).thenAnswer((_) async {});

        await service.deleteEncryptedAtRestKey();

        verify(mockStorage.delete(
          key: 'encryptedAtRestKey',
          iOptions: anyNamed('iOptions'),
        )).called(1);
      });
    });
  });
}
