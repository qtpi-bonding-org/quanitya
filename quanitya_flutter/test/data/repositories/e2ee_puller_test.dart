import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/data/repositories/e2ee_puller.dart';
import 'package:quanitya_flutter/infrastructure/crypto/data_encryption_service.dart';

/// Fake encryption that just base64-encodes/decodes (no real crypto).
class FakeEncryptionService implements IDataEncryptionService {
  @override
  Future<Uint8List> encryptData(String plaintext) async =>
      Uint8List.fromList(utf8.encode(plaintext));

  @override
  Future<String> decryptData(Uint8List ciphertext) async =>
      utf8.decode(ciphertext);

  // Unused in these tests
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late E2EEPuller puller;
  late FakeEncryptionService encryption;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    encryption = FakeEncryptionService();
    puller = E2EEPuller(db, encryption);
  });

  tearDown(() async {
    await puller.dispose();
    await db.close();
  });

  /// Insert an encrypted template directly into the encrypted table.
  Future<void> insertEncryptedTemplate({
    required String id,
    required String name,
    required DateTime updatedAt,
  }) async {
    final json = jsonEncode({
      'id': id,
      'name': name,
      'fields': [],
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': false,
      'isHidden': false,
    });
    // FakeEncryptionService just utf8-encodes, so base64 of that is the blob
    final encryptedData = base64.encode(utf8.encode(json));

    await db.customStatement(
      'INSERT OR REPLACE INTO encrypted_templates (id, encrypted_data, updated_at) VALUES (?, ?, ?)',
      [id, encryptedData, updatedAt.toIso8601String()],
    );
  }

  group('E2EEPuller', () {
    test('initialize sets isListening to true', () async {
      await puller.initialize();
      expect(puller.isListening, true);
    });

    test('initialize is idempotent', () async {
      await puller.initialize();
      await puller.initialize(); // should not throw
      expect(puller.isListening, true);
    });

    test('dispose sets isListening to false', () async {
      await puller.initialize();
      await puller.dispose();
      expect(puller.isListening, false);
    });

    test('processes encrypted template to local table', () async {
      final now = DateTime(2026, 3, 21, 12, 0);
      await insertEncryptedTemplate(id: 'tmpl-1', name: 'Mood', updatedAt: now);

      await puller.initialize();
      // Give streams time to fire
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify local template was created
      final local = await (db.select(db.trackerTemplates)
            ..where((t) => t.id.equals('tmpl-1')))
          .getSingleOrNull();

      expect(local, isNotNull);
      expect(local!.name, 'Mood');
    });

    test('checkpoint advances after processing', () async {
      final now = DateTime.utc(2026, 3, 21, 12, 0);
      await insertEncryptedTemplate(id: 'tmpl-1', name: 'Mood', updatedAt: now);

      await puller.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Check checkpoint was written
      final checkpoint = await (db.select(db.pullerCheckpoints)
            ..where((t) => t.encryptedTable.equals('encrypted_templates')))
          .getSingleOrNull();

      expect(checkpoint, isNotNull);
      // Compare milliseconds to avoid UTC vs local timezone mismatch
      expect(
        checkpoint!.lastProcessedAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });

    test('echo prevention skips older records', () async {
      // Insert a local template first with a newer timestamp
      final newer = DateTime(2026, 3, 21, 14, 0);
      await db.into(db.trackerTemplates).insertOnConflictUpdate(
        TrackerTemplatesCompanion(
          id: const Value('tmpl-1'),
          name: const Value('Mood Updated'),
          fieldsJson: const Value('[]'),
          updatedAt: Value(newer),
          isArchived: const Value(false),
        ),
      );

      // Now insert an older encrypted version
      final older = DateTime(2026, 3, 21, 10, 0);
      await insertEncryptedTemplate(id: 'tmpl-1', name: 'Mood Old', updatedAt: older);

      await puller.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Local should still have the newer version
      final local = await (db.select(db.trackerTemplates)
            ..where((t) => t.id.equals('tmpl-1')))
          .getSingleOrNull();

      expect(local!.name, 'Mood Updated');
    });

    test('resetCheckpoints clears all checkpoints', () async {
      final now = DateTime(2026, 3, 21, 12, 0);
      await insertEncryptedTemplate(id: 'tmpl-1', name: 'Mood', updatedAt: now);

      await puller.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify checkpoint exists
      var count = await db.select(db.pullerCheckpoints).get();
      expect(count, isNotEmpty);

      await puller.resetCheckpoints();

      count = await db.select(db.pullerCheckpoints).get();
      expect(count, isEmpty);
    });
  });
}
