import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../data/dao/log_entry_dual_dao.dart';
import '../../data/db/app_database.dart';
import '../../data/interfaces/analysis_script_interface.dart';
import '../../data/repositories/template_with_aesthetics_repository.dart';
import '../../infrastructure/config/debug_log.dart';
import '../../infrastructure/crypto/crypto_key_repository.dart';
import '../../logic/templates/models/shared/shareable_template.dart';
import '../../logic/templates/services/sharing/shareable_template_staging.dart';
import 'entry_generators.dart';

const _tag = 'dev/services/dev_seeder_service';

/// Development seeder service for populating the database with fake data.
///
/// Loads templates from the quanitya-templates catalog on disk, imports them
/// through the ShareableTemplateStaging pipeline, then generates entries
/// using the slug-keyed generators from entry_generators.dart.
///
/// Only registered in debug builds via @Environment('dev').
@lazySingleton
@Environment('dev')
class DevSeederService {
  final AppDatabase _db;
  final ICryptoKeyRepository _cryptoKeyRepo;
  final LogEntryDualDao _logEntryDao;
  final ShareableTemplateStaging _staging;
  final TemplateWithAestheticsRepository _templateRepo;
  final IAnalysisScriptRepository _scriptRepo;
  final _uuid = const Uuid();

  DevSeederService(
    this._db,
    this._cryptoKeyRepo,
    this._logEntryDao,
    this._staging,
    this._templateRepo,
    this._scriptRepo,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Clear existing data and seed fresh from the template catalog.
  Future<void> clearAndSeed() async {
    await ensureEncryptionKeys();
    await clearAll();
    await seedAll();
  }

  /// Ensure encryption keys are set up for dev/testing.
  ///
  /// Generates account keys if not already initialized.
  /// This is required for DualDAO to work (encrypts data before sync).
  Future<void> ensureEncryptionKeys() async {
    final status = await _cryptoKeyRepo.getKeyStatus();
    if (status == CryptoKeyStatus.notInitialized) {
      Log.d(_tag, 'DevSeeder: Generating encryption keys...');
      await _cryptoKeyRepo.generateAccountKeys();
      // Discard the ultimate key (we don't need it for dev)
      await _cryptoKeyRepo.getUltimateKeyJwkOnce();
      Log.d(_tag, 'DevSeeder: Encryption keys generated');
    } else {
      Log.d(_tag, 'DevSeeder: Encryption keys already exist (status: $status)');
    }
  }

  /// Clear all tables.
  Future<void> clearAll() async {
    // Clear analysis scripts via repository
    final scripts = await _scriptRepo.getAllScripts();
    await Future.wait(scripts.map((s) => _scriptRepo.deleteScript(s.id)));

    // Delete order matters: entries first (FK → templates), then templates.
    await Future.wait([
      _db.delete(_db.logEntries).go(),
      _db.delete(_db.encryptedEntries).go(),
      _db.delete(_db.schedules).go(),
      _db.delete(_db.encryptedSchedules).go(),
    ]);
    await Future.wait([
      _db.delete(_db.templateAesthetics).go(),
      _db.delete(_db.encryptedTemplateAesthetics).go(),
      _db.delete(_db.trackerTemplates).go(),
      _db.delete(_db.encryptedTemplates).go(),
    ]);
  }

  /// Seed all tables from the template catalog on disk.
  ///
  /// For each template slug in the catalog:
  /// 1. Import through ShareableTemplateStaging pipeline
  /// 2. Generate entries using the slug-keyed generator (if one exists)
  /// 3. Generate future todos for selected slugs
  /// All template slugs to seed (must match dev_templates/ asset directories).
  static const _slugs = [
    'cardio-cycling', 'cardio-running', 'cardio-swimming', 'emotion',
    'food', 'habit', 'habits', 'journal', 'lifting', 'medication-log',
    'mood-energy', 'period-tracker', 'sleep', 'symptoms-health',
    'water', 'weight', 'work-productivity',
  ];

  Future<void> seedAll() async {
    final random = Random(42); // seeded for reproducibility

    for (final slug in _slugs) {
      Log.d(_tag, 'DevSeeder: Importing $slug...');
      try {
        final templateId = await _importTemplate(slug);
        await _generateEntries(templateId, slug, random);
      } catch (e, st) {
        Log.d(_tag, 'DevSeeder: FAILED $slug: $e');
        Log.d(_tag, 'DevSeeder: Stack: $st');
      }
    }

    Log.d(_tag, 'DevSeeder: Seeding complete');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private: Template import
  // ─────────────────────────────────────────────────────────────────────────

  /// Import a template from bundled assets via the staging pipeline.
  ///
  /// Returns the saved template's ID.
  Future<String> _importTemplate(String slug) async {
    // 1. Read and parse JSON from bundled assets
    Log.d(_tag, 'DevSeeder: [$slug] Reading asset...');
    final jsonStr = await rootBundle.loadString('dev_templates/$slug/template.json');
    final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;

    Log.d(_tag, 'DevSeeder: [$slug] Parsing ShareableTemplate...');
    final shareable = ShareableTemplate.fromJson(jsonMap);

    // 2. Stage (converts to local format with new UUIDs)
    Log.d(_tag, 'DevSeeder: [$slug] Staging...');
    _staging.stage(shareable);

    // 3. Pull converted template + aesthetics
    final twa = _staging.templateWithAesthetics;
    if (twa == null) {
      throw StateError('Staging produced null for slug "$slug"');
    }

    // 4. Save template + aesthetics via repository
    Log.d(_tag, 'DevSeeder: [$slug] Saving to DB...');
    await _templateRepo.save(twa);

    // 5. Save analysis scripts (remapped with the saved template's ID)
    Log.d(_tag, 'DevSeeder: [$slug] Saving ${_staging.hasScripts ? "scripts" : "no scripts"}...');
    final scripts = _staging.remappedScripts(templateId: twa.template.id);
    for (final script in scripts) {
      await _scriptRepo.saveScript(script);
    }

    // 6. Clear staging for next template
    _staging.clear();

    Log.d(_tag, 'DevSeeder: [$slug] DONE → ${twa.template.id} '
        '(${scripts.length} scripts)');

    return twa.template.id;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private: Entry generation
  // ─────────────────────────────────────────────────────────────────────────

  /// Generate seed entries and todos for a template using its slug-keyed
  /// generator from entry_generators.dart.
  Future<void> _generateEntries(
    String templateId,
    String slug,
    Random random,
  ) async {
    final generator = entryGenerators[slug];
    if (generator == null) {
      Log.d(_tag, 'DevSeeder: No generator for slug "$slug", skipping entries');
      return;
    }

    // Read template back from DB to get field label → UUID mapping
    final rows = await (_db.select(_db.trackerTemplates)
          ..where((t) => t.id.equals(templateId)))
        .get();
    if (rows.isEmpty) {
      Log.d(_tag, 'DevSeeder: Template $templateId not found in DB');
      return;
    }

    final fieldsJson = jsonDecode(rows.first.fieldsJson) as List;
    final labelToId = <String, String>{};
    for (final f in fieldsJson.cast<Map<String, dynamic>>()) {
      labelToId[f['label'] as String] = f['id'] as String;
    }
    final lookup = FieldLookup(labelToId);

    // Generate entries
    final entries = generator(lookup, random);
    final now = DateTime.now();
    for (final entry in entries) {
      await _logEntryDao.upsert(LogEntry(
        id: _uuid.v4(),
        templateId: templateId,
        scheduledFor: null,
        occurredAt: entry.occurredAt,
        dataJson: jsonEncode(entry.data),
        updatedAt: now,
      ));
    }
    Log.d(_tag, 'DevSeeder: Generated ${entries.length} entries for "$slug"');

    // Generate todos for selected slugs
    if (todosForSlugs.contains(slug)) {
      final todos = generateTodos(random);
      for (final todo in todos) {
        await _logEntryDao.upsert(LogEntry(
          id: _uuid.v4(),
          templateId: templateId,
          scheduledFor: todo.scheduledFor,
          occurredAt: null,
          dataJson: '{}',
          updatedAt: now,
        ));
      }
      Log.d(_tag, 'DevSeeder: Generated ${todos.length} todos for "$slug"');
    }
  }
}
