import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../../data/dao/log_entry_dual_dao.dart';
import '../../data/dao/template_aesthetics_dual_dao.dart';
import '../../data/dao/tracker_template_dual_dao.dart';
import '../../infrastructure/crypto/crypto_key_repository.dart';
import '../../data/interfaces/analysis_script_interface.dart';
import '../../logic/analytics/enums/analysis_output_mode.dart';
import '../../logic/analytics/models/analysis_enums.dart';
import '../../logic/analytics/models/analysis_script.dart';
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
  final TemplateAestheticsDualDao _aestheticsDao;
  final IAnalysisScriptRepository _pipelineRepo;
  final _uuid = const Uuid();
  final _random = Random();

  DevSeederService(
    this._db,
    this._cryptoKeyRepo,
    this._logEntryDao,
    this._templateDao,
    this._aestheticsDao,
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
    // Clear analysis scripts via repository
    final pipelines = await _pipelineRepo.getAllScripts();
    for (final p in pipelines) {
      await _pipelineRepo.deleteScript(p.id);
    }

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
    
    final periodTemplateId = await _seedPeriodTemplate();

    // Create hidden templates (for testing hidden feature)
    final journalTemplateId = await _seedJournalTemplate(isHidden: true);
    final medicationTemplateId = await _seedMedicationTemplate(isHidden: true);

    // Create log entries for each template
    await _seedMoodEntries(moodTemplateId.id, moodTemplateId.fields);
    await _seedWeightEntries(weightTemplateId.id, weightTemplateId.fields);
    await _seedWorkoutEntries(workoutTemplateId.id, workoutTemplateId.fields);
    await _seedSleepEntries(sleepTemplateId.id, sleepTemplateId.fields);
    await _seedPeriodEntries(periodTemplateId.id, periodTemplateId.fields);
    await _seedJournalEntries(journalTemplateId.id, journalTemplateId.fields);
    await _seedMedicationEntries(medicationTemplateId.id, medicationTemplateId.fields);

    // Create some future todos
    await _seedFutureTodos(moodTemplateId.id);
    await _seedFutureTodos(workoutTemplateId.id);

    // Seed analysis scripts for templates with numeric fields
    await seedAnalysisScripts();

    // Seed period predictor analysis script (uses timestamps, not generic numeric)
    await _seedPeriodPredictorScript(
      periodTemplateId.id,
      periodTemplateId.fields,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Template Seeders
  // ─────────────────────────────────────────────────────────────────────────

  Future<_SeededTemplate> _seedMoodTemplate() async {
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
    return _SeededTemplate(id, fields);
  }

  Future<_SeededTemplate> _seedWeightTemplate() async {
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
    return _SeededTemplate(id, fields);
  }

  Future<_SeededTemplate> _seedWorkoutTemplate() async {
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
    return _SeededTemplate(id, fields);
  }

  Future<_SeededTemplate> _seedSleepTemplate() async {
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
    return _SeededTemplate(id, fields);
  }

  Future<_SeededTemplate> _seedPeriodTemplate() async {
    final id = _uuid.v4();
    final fields = [
      TemplateField.create(
        label: 'Flow Intensity',
        type: FieldEnum.integer,
        uiElement: UiElementEnum.slider,
        defaultValue: 3,
      ),
      TemplateField.create(
        label: 'Notes',
        type: FieldEnum.text,
        uiElement: UiElementEnum.textArea,
      ),
    ];

    await _templateDao.upsert(TrackerTemplate(
      id: id,
      name: 'Period Tracker',
      fieldsJson: jsonEncode(fields.map((f) => f.toJson()).toList()),
      updatedAt: DateTime.now(),
      isArchived: false,
      isHidden: false,
    ));

    await _seedAesthetics(id, '🩸', 'water_drop', color: '#E91E63');
    return _SeededTemplate(id, fields);
  }

  /// Hidden template - Private Journal (for testing hidden feature)
  Future<_SeededTemplate> _seedJournalTemplate({bool isHidden = false}) async {
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
    return _SeededTemplate(id, fields);
  }

  /// Hidden template - Medication Tracker (for testing hidden feature)
  Future<_SeededTemplate> _seedMedicationTemplate({bool isHidden = false}) async {
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
    return _SeededTemplate(id, fields);
  }

  Future<void> _seedAesthetics(String templateId, String emoji, String icon, {String? color}) async {
    // Build palette - use custom color if provided, otherwise defaults
    final palette = color != null
        ? ColorPaletteData(
            accents: [color, '#4D5B60'], // Custom accent + secondary
            tones: ['#4D5B60', '#7A8A8F'],
          )
        : ColorPaletteData.defaults();

    final model = TemplateAestheticsModel(
      id: _uuid.v4(),
      templateId: templateId,
      emoji: emoji,
      icon: 'material:$icon',
      palette: palette,
      fontConfig: FontConfigData.defaults(),
      colorMappings: {},
      updatedAt: DateTime.now(),
    );

    final entity = _aestheticsDao.modelToEntity(model);
    await _aestheticsDao.upsert(entity);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Entry Seeders
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _seedMoodEntries(String templateId, List<TemplateField> fields) async {
    final f = _FieldIds(fields);
    final now = DateTime.now();

    // Create 30 days of mood entries
    for (var i = 30; i >= 0; i--) {
      if (_random.nextDouble() < 0.15) continue;

      final date = now.subtract(Duration(days: i));

      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          f['Mood Score']: 5 + _random.nextInt(5),
          f['Energy Level']: 3 + _random.nextInt(7),
          f['Notes']: _randomMoodNote(),
        },
      );
    }
  }

  Future<void> _seedWeightEntries(String templateId, List<TemplateField> fields) async {
    final f = _FieldIds(fields);
    final now = DateTime.now();
    var weight = 72.0 + _random.nextDouble() * 5;

    for (var i = 56; i >= 0; i -= 7) {
      final date = now.subtract(Duration(days: i));
      weight += (_random.nextDouble() - 0.5) * 0.8;

      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          f['Weight']: double.parse(weight.toStringAsFixed(1)),
          f['Notes']: '',
        },
      );
    }
  }

  Future<void> _seedWorkoutEntries(String templateId, List<TemplateField> fields) async {
    final f = _FieldIds(fields);
    final now = DateTime.now();
    final workoutTypes = ['Running', 'Cycling', 'Swimming', 'Weights', 'Yoga'];

    for (var i = 30; i >= 0; i--) {
      if (_random.nextDouble() < 0.5) continue;

      final date = now.subtract(Duration(days: i));

      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          f['Workout Type']: workoutTypes[_random.nextInt(workoutTypes.length)],
          f['Duration (min)']: 20 + _random.nextInt(50),
          f['Intensity']: 5 + _random.nextInt(5),
        },
      );
    }
  }

  Future<void> _seedSleepEntries(String templateId, List<TemplateField> fields) async {
    final f = _FieldIds(fields);
    final now = DateTime.now();

    for (var i = 14; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final hours = 6.0 + _random.nextDouble() * 3;
      final quality = 4 + _random.nextInt(6);

      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          f['Hours Slept']: double.parse(hours.toStringAsFixed(1)),
          f['Sleep Quality']: quality,
          f['Woke Up Refreshed']: quality >= 7,
        },
      );
    }
  }

  /// Seed period entries with lognormal-distributed intervals (~28 day mean).
  Future<void> _seedPeriodEntries(String templateId, List<TemplateField> fields) async {
    final f = _FieldIds(fields);
    final now = DateTime.now();

    // Generate ~8 cycle start dates going backwards from ~10 days ago
    // using lognormal intervals (mean ~28 days, some natural variance)
    final logMean = 3.33; // ln(28) ≈ 3.33
    final logStd = 0.12;  // ~12% CV → intervals range ~24–33 days
    var cursor = now.subtract(const Duration(days: 10));

    final cycleDates = <DateTime>[];
    for (var i = 0; i < 8; i++) {
      cycleDates.add(cursor);
      // Box-Muller transform for normal sample → exponentiate for lognormal
      final u1 = _random.nextDouble();
      final u2 = _random.nextDouble();
      final normalSample = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
      final intervalDays = exp(logMean + logStd * normalSample);
      cursor = cursor.subtract(Duration(days: intervalDays.round()));
    }

    // Reverse so they're chronological
    cycleDates.sort();

    // For each cycle start, seed 3-5 days of entries (period duration)
    for (final cycleStart in cycleDates) {
      final durationDays = 3 + _random.nextInt(3); // 3-5 days
      for (var d = 0; d < durationDays; d++) {
        final date = cycleStart.add(Duration(days: d));
        if (date.isAfter(now)) break;

        // Intensity peaks on day 2, tapers off
        final intensity = d == 0 ? 2 + _random.nextInt(2)
            : d == 1 ? 3 + _random.nextInt(3)
            : d == 2 ? 2 + _random.nextInt(3)
            : 1 + _random.nextInt(2);

        await _insertEntry(
          templateId: templateId,
          occurredAt: date,
          data: {
            f['Flow Intensity']: intensity,
            f['Notes']: '',
          },
        );
      }
    }
  }

  Future<void> _seedFutureTodos(String templateId) async {
    final now = DateTime.now();

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

  Future<void> _seedJournalEntries(String templateId, List<TemplateField> fields) async {
    final f = _FieldIds(fields);
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

    for (var i = 20; i >= 0; i -= 2) {
      final date = now.subtract(Duration(days: i));

      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          f['Entry']: entries[_random.nextInt(entries.length)],
          f['Mood']: moods[_random.nextInt(moods.length)],
          f['Private']: true,
        },
      );
    }
  }

  Future<void> _seedMedicationEntries(String templateId, List<TemplateField> fields) async {
    final f = _FieldIds(fields);
    final now = DateTime.now();

    for (var i = 14; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final taken = _random.nextDouble() > 0.1;

      await _insertEntry(
        templateId: templateId,
        occurredAt: date,
        data: {
          f['Medication']: 'Vitamin D',
          f['Dosage']: '1000 IU',
          f['Taken']: taken,
          f['Side Effects']: taken && _random.nextDouble() < 0.1 ? 'Mild headache' : '',
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
  // Analysis Script Seeders
  // ─────────────────────────────────────────────────────────────────────────

  /// Seeds analysis scripts for all templates with numeric fields.
  /// Call from dev tools button only.
  Future<void> seedAnalysisScripts() async {
    // Clear any existing scripts first (removes stale test data)
    final existing = await _pipelineRepo.getAllScripts();
    for (final p in existing) {
      await _pipelineRepo.deleteScript(p.id);
    }

    final templates = await _db.select(_db.trackerTemplates).get();
    if (templates.isEmpty) {
      throw Exception('No templates found. Seed fake data first.');
    }

    bool seeded = false;
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
        await _seedAnalysisScriptsForField(template.id, fieldLabel);
        seeded = true;
      }
    }

    if (!seeded) {
      throw Exception('No templates with numeric fields found.');
    }
  }

  Future<void> _seedAnalysisScriptsForField(
    String templateId,
    String fieldLabel,
  ) async {
    final now = DateTime.now();
    final fieldId = '$templateId:$fieldLabel';

    await _pipelineRepo.saveScript(AnalysisScriptModel(
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

    await _pipelineRepo.saveScript(AnalysisScriptModel(
      id: _uuid.v4(),
      name: 'Smoothed + Residuals',
      fieldId: fieldId,
      outputMode: AnalysisOutputMode.vector,
      snippetLanguage: AnalysisSnippetLanguage.js,
      snippet: '''// 3-day moving average + residuals
const windowSize = 3;
const movingAvg = [];

for (let i = windowSize - 1; i < data.values.length; i++) {
  const window = data.values.slice(i - windowSize + 1, i + 1);
  movingAvg.push(ss.mean(window));
}

// Residuals = original - smoothed (aligned to same window)
const residuals = [];
for (let i = 0; i < movingAvg.length; i++) {
  residuals.push(data.values[i + windowSize - 1] - movingAvg[i]);
}

return [
  { label: 'Smoothed', values: movingAvg },
  { label: 'Residuals', values: residuals }
];''',
      reasoning: 'Moving average with residuals showing deviation from trend',
      updatedAt: now,
    ));

    await _pipelineRepo.saveScript(AnalysisScriptModel(
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

    await _pipelineRepo.saveScript(AnalysisScriptModel(
      id: _uuid.v4(),
      name: 'Rolling Statistics',
      fieldId: fieldId,
      outputMode: AnalysisOutputMode.matrix,
      snippetLanguage: AnalysisSnippetLanguage.js,
      snippet: '''// 5-day rolling mean + std dev
const windowSize = 5;
const rollingMean = [];
const rollingStd = [];
const ts = [];

for (let i = windowSize - 1; i < data.values.length; i++) {
  const window = data.values.slice(i - windowSize + 1, i + 1);
  rollingMean.push(ss.mean(window));
  rollingStd.push(ss.standardDeviation(window));
  ts.push(data.timestamps[i]);
}

return [
  { label: 'Rolling Mean', values: rollingMean, timestamps: ts },
  { label: 'Rolling Std', values: rollingStd, timestamps: ts }
];''',
      reasoning: '5-day rolling mean and standard deviation for trend detection',
      updatedAt: now,
    ));
  }

  /// Seed the Bayesian lognormal period predictor script.
  ///
  /// Uses inter-event timestamps to fit a Normal-Inverse-Gamma conjugate
  /// posterior on log-intervals, then produces a Student-t predictive
  /// distribution for the next cycle length and predicted date.
  Future<void> _seedPeriodPredictorScript(
    String templateId,
    List<TemplateField> fields,
  ) async {
    // Use "Flow Intensity" as the numeric field binding
    final fieldLabel = 'Flow Intensity';
    final fieldId = '$templateId:$fieldLabel';
    final now = DateTime.now();

    await _pipelineRepo.saveScript(AnalysisScriptModel(
      id: _uuid.v4(),
      name: 'Period Predictor (Bayesian)',
      fieldId: fieldId,
      outputMode: AnalysisOutputMode.scalar,
      snippetLanguage: AnalysisSnippetLanguage.js,
      snippet: _periodPredictorSnippet,
      reasoning:
          'Bayesian lognormal model: treats log(interval) as normally distributed, '
          'uses Normal-Inverse-Gamma conjugate prior for online learning. '
          'The predictive distribution is Student-t, exponentiated back to days. '
          'Returns predicted next date with 90% credible interval.',
      updatedAt: now,
    ));
  }

  static const _periodPredictorSnippet = r"""
// Bayesian Lognormal Period Predictor
// ------------------------------------
// Model: inter-cycle intervals ~ LogNormal(mu, sigma^2)
//   equivalently: log(interval) ~ Normal(mu, sigma^2)
// Prior: Normal-Inverse-Gamma conjugate
//   mu | sigma^2 ~ N(mu0, sigma^2 / kappa0)
//   sigma^2 ~ IG(nu0/2, nu0*sigma0^2/2)
// Posterior update is closed-form; predictive is Student-t.

const MS_PER_DAY = 86400000;

// ── 1. Extract cycle start dates ──────────────────────────────
// Group entries by cycle: a new cycle starts when there's a gap > 10 days
const sortedTs = data.timestamps.slice().sort((a, b) => a - b);
const cycleStarts = [sortedTs[0]];

for (let i = 1; i < sortedTs.length; i++) {
  const gapDays = (sortedTs[i] - sortedTs[i - 1]) / MS_PER_DAY;
  if (gapDays > 10) {
    cycleStarts.push(sortedTs[i]);
  }
}

if (cycleStarts.length < 3) {
  return [
    { label: 'Status', value: 0, unit: 'Need 3+ cycles for prediction' }
  ];
}

// ── 2. Compute inter-cycle intervals (days) ───────────────────
const intervals = [];
for (let i = 1; i < cycleStarts.length; i++) {
  intervals.push((cycleStarts[i] - cycleStarts[i - 1]) / MS_PER_DAY);
}
const logIntervals = intervals.map(d => Math.log(d));

// ── 3. Weakly informative prior (centered on ~28 days) ────────
const mu0    = Math.log(28);  // prior mean for log-interval
const kappa0 = 1;             // prior strength (1 pseudo-observation)
const nu0    = 2;             // prior df
const sigma0_sq = 0.04;       // prior variance for log-interval (~20% CV)

// ── 4. Normal-Inverse-Gamma posterior update ──────────────────
const n       = logIntervals.length;
const xbar    = ss.mean(logIntervals);
const S       = ss.sumNthPowerDeviations(logIntervals, 2);

const kappa_n = kappa0 + n;
const mu_n    = (kappa0 * mu0 + n * xbar) / kappa_n;
const nu_n    = nu0 + n;
const nu_sigma_n = nu0 * sigma0_sq + S + (kappa0 * n * (xbar - mu0) ** 2) / kappa_n;
const sigma_n_sq = nu_sigma_n / nu_n;

// ── 5. Predictive distribution: Student-t in log-space ────────
// log(next_interval) ~ t_{nu_n}(mu_n, sigma_n^2 * (1 + 1/kappa_n))
const predScale = Math.sqrt(sigma_n_sq * (1 + 1 / kappa_n));
const predDf    = nu_n;

// Point estimate: exp(mu_n) (median of lognormal predictive)
const predictedDays = Math.exp(mu_n);

// 90% credible interval via Student-t quantile (0.95 one-sided)
const tCrit = jStat.studentt.inv(0.95, predDf);

const logLower = mu_n - tCrit * predScale;
const logUpper = mu_n + tCrit * predScale;
const lowerDays = Math.exp(logLower);
const upperDays = Math.exp(logUpper);

// ── 6. Predicted next date ────────────────────────────────────
const lastCycleStart = cycleStarts[cycleStarts.length - 1];
const predictedDate = new Date(lastCycleStart + predictedDays * MS_PER_DAY);
const lowerDate = new Date(lastCycleStart + lowerDays * MS_PER_DAY);
const upperDate = new Date(lastCycleStart + upperDays * MS_PER_DAY);

return [
  { label: 'Predicted Cycle', value: Math.round(predictedDays * 10) / 10, unit: 'days' },
  { label: '90% CI Lower', value: Math.round(lowerDays * 10) / 10, unit: 'days' },
  { label: '90% CI Upper', value: Math.round(upperDays * 10) / 10, unit: 'days' },
  { label: 'Next Period', value: predictedDate.getTime(), unit: 'timestamp' },
  { label: 'As Early As', value: lowerDate.getTime(), unit: 'timestamp' },
  { label: 'As Late As', value: upperDate.getTime(), unit: 'timestamp' },
  { label: 'Cycles Used', value: intervals.length, unit: 'intervals' },
  { label: 'Observed Mean', value: Math.round(ss.mean(intervals) * 10) / 10, unit: 'days' },
  { label: 'Data From', value: data.timestamps[0], unit: 'timestamp' },
  { label: 'Data To', value: data.timestamps[data.timestamps.length - 1], unit: 'timestamp' }
];
""";

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

/// Bundles a template ID with its fields so entry seeders can use field IDs.
class _SeededTemplate {
  final String id;
  final List<TemplateField> fields;
  const _SeededTemplate(this.id, this.fields);
}

/// Looks up field IDs by label for seed data maps.
class _FieldIds {
  final Map<String, String> _labelToId;
  _FieldIds(List<TemplateField> fields)
      : _labelToId = {for (final f in fields) f.label: f.id};

  String operator [](String label) => _labelToId[label]!;
}
