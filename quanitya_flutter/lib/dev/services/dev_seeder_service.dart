import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../../data/dao/log_entry_dual_dao.dart';
import '../../data/dao/tracker_template_dual_dao.dart';
import '../../infrastructure/crypto/crypto_key_repository.dart';
import '../../data/interfaces/analysis_pipeline_interface.dart';
import '../../logic/analytics/enums/analysis_output_mode.dart';
import '../../logic/analytics/models/analysis_enums.dart';
import '../../logic/analytics/models/analysis_pipeline.dart';
import '../../logic/templates/enums/field_enum.dart';
import '../../logic/templates/enums/ui_element_enum.dart';
import '../../logic/templates/models/shared/template_field.dart';
import '../../logic/templates/models/shared/template_aesthetics.dart';

/// Development seeder service for populating the database with fake data.
///
/// Use this to quickly test UI without manually entering data.
/// Only available in debug builds.
@lazySingleton
class DevSeederService {
  final AppDatabase _db;
  final ICryptoKeyRepository _cryptoKeyRepo;
  final LogEntryDualDao _logEntryDao;
  final TrackerTemplateDualDao _templateDao;
  final IAnalysisPipelineRepository _pipelineRepo;
  final _uuid = const Uuid();
  final _random = Random();

  DevSeederService(
    this._db,
    this._cryptoKeyRepo,
    this._logEntryDao,
    this._templateDao,
    this._pipelineRepo,
  );

  /// Clear all data and seed with fresh fake data.
  Future<void> clearAndSeed() async {
    await clearAll();
    await ensureEncryptionKeys();
    await seedAll();
  }

  /// Ensure encryption keys are set up for dev/testing.
  /// 
  /// Generates account keys if not already initialized.
  /// This is required for DualDAO to work (encrypts data before sync).
  Future<void> ensureEncryptionKeys() async {
    final status = await _cryptoKeyRepo.getKeyStatus();
    if (status == CryptoKeyStatus.notInitialized) {
      debugPrint('DevSeeder: Generating encryption keys...');
      await _cryptoKeyRepo.generateAccountKeys();
      // Discard the ultimate key (we don't need it for dev)
      await _cryptoKeyRepo.getUltimateKeyJwkOnce();
      debugPrint('DevSeeder: Encryption keys generated');
    } else {
      debugPrint('DevSeeder: Encryption keys already exist (status: $status)');
    }
  }

  /// Clear all tables.
  Future<void> clearAll() async {
    await _db.delete(_db.logEntries).go();
    await _db.delete(_db.schedules).go();
    await _db.delete(_db.templateAesthetics).go();
    await _db.delete(_db.trackerTemplates).go();
    await _db.delete(_db.encryptedEntries).go();
    await _db.delete(_db.encryptedSchedules).go();
    await _db.delete(_db.encryptedTemplates).go();
  }

  /// Seed all tables with fake data.
  Future<void> seedAll() async {
    // Create templates
    final moodTemplateId = await _seedMoodTemplate();
    final weightTemplateId = await _seedWeightTemplate();
    final workoutTemplateId = await _seedWorkoutTemplate();
    final sleepTemplateId = await _seedSleepTemplate();
    
    // Create hidden templates (for testing hidden feature)
    final journalTemplateId = await _seedJournalTemplate(isHidden: true);
    final medicationTemplateId = await _seedMedicationTemplate(isHidden: true);

    // Create log entries for each template
    await _seedMoodEntries(moodTemplateId);
    await _seedWeightEntries(weightTemplateId);
    await _seedWorkoutEntries(workoutTemplateId);
    await _seedSleepEntries(sleepTemplateId);
    await _seedJournalEntries(journalTemplateId);
    await _seedMedicationEntries(medicationTemplateId);

    // Create some future todos
    await _seedFutureTodos(moodTemplateId);
    await _seedFutureTodos(workoutTemplateId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Template Seeders
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> _seedMoodTemplate() async {
    final id = _uuid.v4();
    final fields = [
      TemplateField.create(
        label: 'Mood Score',
        type: FieldEnum.integer,
        uiElement: UiElementEnum.slider,
        defaultValue: 7,
      ),
      TemplateField.create(
        label: 'Energy Level',
        type: FieldEnum.integer,
        uiElement: UiElementEnum.stepper,
        defaultValue: 5,
      ),
      TemplateField.create(
        label: 'Notes',
        type: FieldEnum.text,
        uiElement: UiElementEnum.textArea,
      ),
    ];

    await _templateDao.upsert(TrackerTemplate(
      id: id,
      name: 'Mood Tracker',
      fieldsJson: jsonEncode(fields.map((f) => f.toJson()).toList()),
      updatedAt: DateTime.now(),
      isArchived: false,
      isHidden: false,
    ));

    await _seedAesthetics(id, '😊', 'mood_outline');
    return id;
  }

  Future<String> _seedWeightTemplate() async {
    final id = _uuid.v4();
    final fields = [
      TemplateField.create(
        label: 'Weight',
        type: FieldEnum.float,
        uiElement: UiElementEnum.textField,
        defaultValue: 70.0,
      ),
      TemplateField.create(
        label: 'Notes',
        type: FieldEnum.text,
        uiElement: UiElementEnum.textArea,
      ),
    ];

    await _templateDao.upsert(TrackerTemplate(
      id: id,
      name: 'Weight Log',
      fieldsJson: jsonEncode(fields.map((f) => f.toJson()).toList()),
      updatedAt: DateTime.now(),
      isArchived: false,
      isHidden: false,
    ));

    await _seedAesthetics(id, '⚖️', 'scale');
    return id;
  }

  Future<String> _seedWorkoutTemplate() async {
    final id = _uuid.v4();
    final fields = [
      TemplateField.create(
        label: 'Workout Type',
        type: FieldEnum.enumerated,
        uiElement: UiElementEnum.dropdown,
        options: ['Running', 'Cycling', 'Swimming', 'Weights', 'Yoga'],
        defaultValue: 'Running',
      ),
      TemplateField.create(
        label: 'Duration (min)',
        type: FieldEnum.integer,
        uiElement: UiElementEnum.stepper,
        defaultValue: 30,
      ),
      TemplateField.create(
        label: 'Intensity',
        type: FieldEnum.integer,
        uiElement: UiElementEnum.slider,
        defaultValue: 7,
      ),
    ];

    await _templateDao.upsert(TrackerTemplate(
      id: id,
      name: 'Workout',
      fieldsJson: jsonEncode(fields.map((f) => f.toJson()).toList()),
      updatedAt: DateTime.now(),
      isArchived: false,
      isHidden: false,
    ));

    await _seedAesthetics(id, '💪', 'fitness_center');
    return id;
  }

  Future<String> _seedSleepTemplate() async {
    final id = _uuid.v4();
    final fields = [
      TemplateField.create(
        label: 'Hours Slept',
        type: FieldEnum.float,
        uiElement: UiElementEnum.slider,
        defaultValue: 7.5,
      ),
      TemplateField.create(
        label: 'Sleep Quality',
        type: FieldEnum.integer,
        uiElement: UiElementEnum.slider,
        defaultValue: 7,
      ),
      TemplateField.create(
        label: 'Woke Up Refreshed',
        type: FieldEnum.boolean,
        uiElement: UiElementEnum.toggleSwitch,
        defaultValue: true,
      ),
    ];

    await _templateDao.upsert(TrackerTemplate(
      id: id,
      name: 'Sleep Log',
      fieldsJson: jsonEncode(fields.map((f) => f.toJson()).toList()),
      updatedAt: DateTime.now(),
      isArchived: false,
      isHidden: false,
    ));

    await _seedAesthetics(id, '😴', 'bedtime');
    return id;
  }

  /// Hidden template - Private Journal (for testing hidden feature)
  Future<String> _seedJournalTemplate({bool isHidden = false}) async {
    final id = _uuid.v4();
    final fields = [
      TemplateField.create(
        label: 'Entry',
        type: FieldEnum.text,
      ),
      TemplateField.create(
        label: 'Mood',
        type: FieldEnum.enumerated,
        options: ['Happy', 'Sad', 'Anxious', 'Calm', 'Angry', 'Grateful'],
        defaultValue: 'Calm',
      ),
      TemplateField.create(
        label: 'Private',
        type: FieldEnum.boolean,
        defaultValue: true,
      ),
    ];

    await _templateDao.upsert(TrackerTemplate(
      id: id,
      name: 'Private Journal',
      fieldsJson: jsonEncode(fields.map((f) => f.toJson()).toList()),
      updatedAt: DateTime.now(),
      isArchived: false,
      isHidden: isHidden,
    ));

    await _seedAesthetics(id, '🔒', 'lock', color: '#9C27B0'); // Purple
    return id;
  }

  /// Hidden template - Medication Tracker (for testing hidden feature)
  Future<String> _seedMedicationTemplate({bool isHidden = false}) async {
    final id = _uuid.v4();
    final fields = [
      TemplateField.create(
        label: 'Medication',
        type: FieldEnum.text,
      ),
      TemplateField.create(
        label: 'Dosage',
        type: FieldEnum.text,
      ),
      TemplateField.create(
        label: 'Taken',
        type: FieldEnum.boolean,
        defaultValue: true,
      ),
      TemplateField.create(
        label: 'Side Effects',
        type: FieldEnum.text,
      ),
    ];

    await _templateDao.upsert(TrackerTemplate(
      id: id,
      name: 'Medication Log',
      fieldsJson: jsonEncode(fields.map((f) => f.toJson()).toList()),
      updatedAt: DateTime.now(),
      isArchived: false,
      isHidden: isHidden,
    ));

    await _seedAesthetics(id, '💊', 'medication', color: '#E91E63'); // Pink
    return id;
  }

  Future<void> _seedAesthetics(String templateId, String emoji, String icon, {String? color}) async {
    // Build palette - use custom color if provided, otherwise defaults
    final palette = color != null 
        ? ColorPaletteData(
            accents: [color, '#4D5B60'], // Custom accent + secondary
            tones: ['#4D5B60', '#7A8A8F'],
          )
        : ColorPaletteData.defaults();
    
    final aesthetics = TemplateAestheticsModel(
      id: _uuid.v4(),
      templateId: templateId,
      emoji: emoji,
      icon: 'material:$icon',
      palette: palette,
      fontConfig: FontConfigData.defaults(),
      colorMappings: {},
      updatedAt: DateTime.now(),
    );

    await _db.into(_db.templateAesthetics).insert(
      TemplateAestheticsCompanion.insert(
        id: aesthetics.id,
        templateId: templateId,
        icon: Value('material:$icon'),
        emoji: Value(emoji),
        paletteJson: aesthetics.paletteJson,
        fontConfigJson: aesthetics.fontConfigJson,
        colorMappingsJson: aesthetics.colorMappingsJson,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Entry Seeders
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _seedMoodEntries(String templateId) async {
    final now = DateTime.now();
    
    // Create 30 days of mood entries
    for (var i = 30; i >= 0; i--) {
      // Skip some days randomly
      if (_random.nextDouble() < 0.15) continue;
      
      final date = now.subtract(Duration(days: i));
      final moodScore = 5 + _random.nextInt(5); // 5-9
      final energyLevel = 3 + _random.nextInt(7); // 3-9
      
      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          'Mood Score': moodScore,
          'Energy Level': energyLevel,
          'Notes': _randomMoodNote(),
        },
      );
    }
  }

  Future<void> _seedWeightEntries(String templateId) async {
    final now = DateTime.now();
    var weight = 72.0 + _random.nextDouble() * 5; // Start between 72-77
    
    // Create weekly weight entries for 8 weeks
    for (var i = 56; i >= 0; i -= 7) {
      final date = now.subtract(Duration(days: i));
      weight += (_random.nextDouble() - 0.5) * 0.8; // Fluctuate ±0.4kg
      
      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          'Weight': double.parse(weight.toStringAsFixed(1)),
          'Notes': '',
        },
      );
    }
  }

  Future<void> _seedWorkoutEntries(String templateId) async {
    final now = DateTime.now();
    final workoutTypes = ['Running', 'Cycling', 'Swimming', 'Weights', 'Yoga'];
    
    // Create 20 workout entries over 30 days
    for (var i = 30; i >= 0; i--) {
      // Only workout ~3-4 times per week
      if (_random.nextDouble() < 0.5) continue;
      
      final date = now.subtract(Duration(days: i));
      
      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          'Workout Type': workoutTypes[_random.nextInt(workoutTypes.length)],
          'Duration (min)': 20 + _random.nextInt(50), // 20-70 min
          'Intensity': 5 + _random.nextInt(5), // 5-9
        },
      );
    }
  }

  Future<void> _seedSleepEntries(String templateId) async {
    final now = DateTime.now();
    
    // Create 14 days of sleep entries
    for (var i = 14; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final hours = 6.0 + _random.nextDouble() * 3; // 6-9 hours
      final quality = 4 + _random.nextInt(6); // 4-9
      
      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          'Hours Slept': double.parse(hours.toStringAsFixed(1)),
          'Sleep Quality': quality,
          'Woke Up Refreshed': quality >= 7,
        },
      );
    }
  }

  Future<void> _seedFutureTodos(String templateId) async {
    final now = DateTime.now();

    // Create 5 future todos
    for (var i = 1; i <= 5; i++) {
      final scheduledFor = now.add(Duration(days: i));

      await _logEntryDao.upsert(LogEntry(
        id: _uuid.v4(),
        templateId: templateId,
        scheduledFor: scheduledFor,
        occurredAt: null,
        dataJson: '{}',
        updatedAt: now,
      ));
    }
  }

  Future<void> _seedJournalEntries(String templateId) async {
    final now = DateTime.now();
    final moods = ['Happy', 'Sad', 'Anxious', 'Calm', 'Angry', 'Grateful'];
    final entries = [
      'Had a really productive day today. Feeling accomplished.',
      'Struggling with some anxiety about the upcoming presentation.',
      'Grateful for the support from friends and family.',
      'Need to work on being more present in the moment.',
      'Feeling overwhelmed but trying to take it one step at a time.',
      'Good conversation with a friend helped clear my mind.',
      'Journaling helps me process my thoughts better.',
    ];
    
    // Create 10 journal entries over 20 days
    for (var i = 20; i >= 0; i -= 2) {
      final date = now.subtract(Duration(days: i));
      
      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          'Entry': entries[_random.nextInt(entries.length)],
          'Mood': moods[_random.nextInt(moods.length)],
          'Private': true,
        },
      );
    }
  }

  Future<void> _seedMedicationEntries(String templateId) async {
    final now = DateTime.now();
    
    // Create 14 days of medication entries
    for (var i = 14; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final taken = _random.nextDouble() > 0.1; // 90% compliance
      
      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          'Medication': 'Vitamin D',
          'Dosage': '1000 IU',
          'Taken': taken,
          'Side Effects': taken && _random.nextDouble() < 0.1 ? 'Mild headache' : '',
        },
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _insertEntry({
    required String templateId,
    required DateTime occurredAt,
    required Map<String, dynamic> data,
  }) async {
    await _logEntryDao.upsert(LogEntry(
      id: _uuid.v4(),
      templateId: templateId,
      scheduledFor: null,
      occurredAt: occurredAt,
      dataJson: jsonEncode(data),
      updatedAt: DateTime.now(),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Analysis Pipeline Seeders
  // ─────────────────────────────────────────────────────────────────────────

  /// Seeds analysis pipelines for the first numeric-field template found.
  /// Call from dev tools button only.
  Future<void> seedAnalysisPipelines() async {
    // Find the first template with numeric fields (likely Mood Tracker)
    final templates = await _db.select(_db.trackerTemplates).get();
    if (templates.isEmpty) {
      throw Exception('No templates found. Seed fake data first.');
    }

    // Find a template with numeric fields by parsing fieldsJson
    for (final template in templates) {
      final fieldsJson = jsonDecode(template.fieldsJson) as List;
      final numericField = fieldsJson.cast<Map<String, dynamic>>().where(
        (f) {
          final type = f['type'] as String?;
          return type == 'integer' || type == 'float' || type == 'dimension';
        },
      ).firstOrNull;

      if (numericField != null) {
        final fieldLabel = numericField['label'] as String;
        await _seedAnalysisPipelinesForField(template.id, fieldLabel);
        return;
      }
    }

    throw Exception('No templates with numeric fields found.');
  }

  Future<void> _seedAnalysisPipelinesForField(
    String templateId,
    String fieldLabel,
  ) async {
    final now = DateTime.now();
    final fieldId = '$templateId:$fieldLabel';

    await _pipelineRepo.savePipeline(AnalysisPipelineModel(
      id: _uuid.v4(),
      name: 'Mood Statistics',
      fieldId: fieldId,
      outputMode: AnalysisOutputMode.scalar,
      snippetLanguage: AnalysisSnippetLanguage.js,
      snippet: '''// Calculate mood statistics
return [
  { label: 'Mean', value: ss.mean(data.values), unit: 'pts' },
  { label: 'Std Dev', value: ss.standardDeviation(data.values), unit: 'pts' },
  { label: 'Min', value: ss.min(data.values), unit: 'pts' },
  { label: 'Max', value: ss.max(data.values), unit: 'pts' }
];''',
      reasoning: 'Basic descriptive statistics for mood scores',
      updatedAt: now,
    ));

    await _pipelineRepo.savePipeline(AnalysisPipelineModel(
      id: _uuid.v4(),
      name: '3-Day Moving Average',
      fieldId: fieldId,
      outputMode: AnalysisOutputMode.vector,
      snippetLanguage: AnalysisSnippetLanguage.js,
      snippet: '''// Calculate 3-day moving average
const windowSize = 3;
const movingAvg = [];

for (let i = windowSize - 1; i < data.values.length; i++) {
  const window = data.values.slice(i - windowSize + 1, i + 1);
  movingAvg.push(ss.mean(window));
}

return {
  label: '3-Day MA',
  values: movingAvg
};''',
      reasoning: 'Smooths daily fluctuations to show mood trend',
      updatedAt: now,
    ));

    await _pipelineRepo.savePipeline(AnalysisPipelineModel(
      id: _uuid.v4(),
      name: 'Smoothed Time Series',
      fieldId: fieldId,
      outputMode: AnalysisOutputMode.matrix,
      snippetLanguage: AnalysisSnippetLanguage.js,
      snippet: '''// Apply 3-point smoothing
const smoothed = data.values.map((v, i) => {
  if (i === 0 || i === data.values.length - 1) return v;
  return (data.values[i-1] + v + data.values[i+1]) / 3;
});

return { values: smoothed };''',
      reasoning: 'Neighbor-averaged smoothing for visualization',
      updatedAt: now,
    ));
  }

  String _randomMoodNote() {
    final notes = [
      '',
      'Feeling good today!',
      'A bit tired',
      'Great day at work',
      'Stressed about deadlines',
      'Relaxing weekend',
      'Had a nice walk',
      'Coffee helped',
      '',
      '',
    ];
    return notes[_random.nextInt(notes.length)];
  }
}
