/// Fake template data for golden screenshot tests.
///
/// Provides 8 realistic templates with fields and defaults so the home screen
/// renders populated cards with quick-log buttons highlighted.
/// Also provides fake timeline items and schedules for past/future screenshots.
library;

import 'package:quanitya_flutter/data/dao/log_entry_query_dao.dart';
import 'package:quanitya_flutter/design_system/primitives/quanitya_date_format.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart'
    show TemplateWithAesthetics;
import 'package:quanitya_flutter/logic/log_entries/models/log_entry.dart';
import 'package:quanitya_flutter/logic/schedules/models/schedule.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_aesthetics.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';
import 'package:quanitya_flutter/features/home/cubits/timeline_data_state.dart';
import 'package:quanitya_flutter/features/results/cubits/results_list_state.dart';
import 'package:quanitya_flutter/features/visualization/cubits/visualization_state.dart';
import 'package:quanitya_flutter/logic/analysis/enums/analysis_output_mode.dart';
import 'package:quanitya_flutter/logic/analysis/models/analysis_enums.dart';
import 'package:quanitya_flutter/logic/analysis/models/analysis_output.dart';
import 'package:quanitya_flutter/logic/analysis/models/analysis_script.dart';
import 'package:quanitya_flutter/features/schedules/cubits/schedule_list_state.dart';
import 'package:quanitya_flutter/data/repositories/data_retrieval_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Template IDs (stable UUIDs for cross-referencing)
// ─────────────────────────────────────────────────────────────────────────────

const _liftingId = '00000000-0000-0000-0000-000000000001';
const _periodId = '00000000-0000-0000-0000-000000000002';
const _waterId = '00000000-0000-0000-0000-000000000003';
const _sleepId = '00000000-0000-0000-0000-000000000004';
const _emotionId = '00000000-0000-0000-0000-000000000005';
const _cyclingId = '00000000-0000-0000-0000-000000000006';
const _journalId = '00000000-0000-0000-0000-000000000007';
const _medicationId = '00000000-0000-0000-0000-000000000008';

// ─────────────────────────────────────────────────────────────────────────────
// Localized names for templates and fields
// ─────────────────────────────────────────────────────────────────────────────

/// Translation map: english key → {locale: translated}.
/// Template names and field labels for store screenshots.
const _t = <String, Map<String, String>>{
  // Template names
  'Lifting':    {'es': 'Pesas',       'fr': 'Musculation',  'pt': 'Musculação'},
  'Period':     {'es': 'Período',     'fr': 'Règles',       'pt': 'Período'},
  'Water':      {'es': 'Agua',        'fr': 'Eau',          'pt': 'Água'},
  'Sleep':      {'es': 'Sueño',       'fr': 'Sommeil',      'pt': 'Sono'},
  'Emotion':    {'es': 'Emoción',     'fr': 'Émotion',      'pt': 'Emoção'},
  'Cycling':    {'es': 'Ciclismo',    'fr': 'Cyclisme',     'pt': 'Ciclismo'},
  'Journal':    {'es': 'Diario',      'fr': 'Journal',      'pt': 'Diário'},
  'Medication': {'es': 'Medicación',  'fr': 'Médicaments',  'pt': 'Medicação'},
  // Field labels
  'Exercise':       {'es': 'Ejercicio',          'fr': 'Exercice',           'pt': 'Exercício'},
  'Weight':         {'es': 'Peso',               'fr': 'Poids',             'pt': 'Peso'},
  'Reps':           {'es': 'Repeticiones',       'fr': 'Répétitions',       'pt': 'Repetições'},
  'Flow Intensity': {'es': 'Intensidad',         'fr': 'Intensité',         'pt': 'Intensidade'},
  'Cramps':         {'es': 'Calambres',          'fr': 'Crampes',           'pt': 'Cólicas'},
  'Notes':          {'es': 'Notas',              'fr': 'Notes',             'pt': 'Notas'},
  'Glasses':        {'es': 'Vasos',              'fr': 'Verres',            'pt': 'Copos'},
  'Hours':          {'es': 'Horas',              'fr': 'Heures',            'pt': 'Horas'},
  'Quality':        {'es': 'Calidad',            'fr': 'Qualité',           'pt': 'Qualidade'},
  'Feeling':        {'es': 'Sentimiento',        'fr': 'Sentiment',         'pt': 'Sentimento'},
  'Intensity':      {'es': 'Intensidad',         'fr': 'Intensité',         'pt': 'Intensidade'},
  'Distance':       {'es': 'Distancia',          'fr': 'Distance',          'pt': 'Distância'},
  'Duration':       {'es': 'Duración',           'fr': 'Durée',             'pt': 'Duração'},
  'Entry':          {'es': 'Entrada',            'fr': 'Entrée',            'pt': 'Entrada'},
  'Taken':          {'es': 'Tomado',             'fr': 'Pris',              'pt': 'Tomado'},
  // Enum options
  'Poor': {'es': 'Mala', 'fr': 'Mauvaise', 'pt': 'Ruim'},
  'Fair': {'es': 'Regular', 'fr': 'Passable', 'pt': 'Razoável'},
  'Good': {'es': 'Buena', 'fr': 'Bonne', 'pt': 'Boa'},
  'Great': {'es': 'Excelente', 'fr': 'Excellente', 'pt': 'Excellente'},
  'Happy': {'es': 'Feliz', 'fr': 'Heureux', 'pt': 'Feliz'},
  'Calm': {'es': 'Tranquilo', 'fr': 'Calme', 'pt': 'Calmo'},
  'Anxious': {'es': 'Ansioso', 'fr': 'Anxieux', 'pt': 'Ansioso'},
  'Sad': {'es': 'Triste', 'fr': 'Triste', 'pt': 'Triste'},
  'Angry': {'es': 'Enojado', 'fr': 'En colère', 'pt': 'Irritado'},
  // Data previews for timeline
  'Bench Press': {'es': 'Press banca', 'fr': 'Développé couché', 'pt': 'Supino'},
  'Deadlift':    {'es': 'Peso muerto', 'fr': 'Soulevé de terre', 'pt': 'Levantamento terra'},
  'Feeling okay today': {'es': 'Me siento bien hoy', 'fr': 'Je me sens bien', 'pt': 'Me sentindo bem'},
  // Analysis reasoning
  'Computes basic statistics and linear trend for weight progression.': {
    'es': 'Calcula estadísticas básicas y tendencia lineal para progresión de peso.',
    'fr': 'Calcule les statistiques de base et la tendance linéaire de progression du poids.',
    'pt': 'Calcula estatísticas básicas e tendência linear para progressão de peso.',
  },
};

/// Translate a string to the given locale. Returns original if no translation.
String tr(String key, String locale) =>
    locale == 'en' ? key : (_t[key]?[locale] ?? key);

/// Translate a list of strings.
List<String> _trList(List<String> keys, String locale) =>
    keys.map((k) => tr(k, locale)).toList();

// ─────────────────────────────────────────────────────────────────────────────
// Templates with fields + defaults (enables quick-log button highlighting)
// ─────────────────────────────────────────────────────────────────────────────

/// Eight templates matching the dev_templates catalog, with exact aesthetics
/// and fields with defaults so quick-log buttons are highlighted.
final List<TemplateWithAesthetics> fakeTemplates = [
  _template(
    id: _liftingId,
    name: 'Lifting',
    icon: 'material:fitness_center',
    emoji: '\u{1F4AA}',
    accents: ['#78909C', '#90A4AE'],
    tones: ['#37474F', '#455A64'],
    fields: [
      TemplateField(id: 'f-lift-1', label: 'Exercise', type: FieldEnum.text, uiElement: UiElementEnum.textField, defaultValue: 'Bench Press'),
      TemplateField(id: 'f-lift-2', label: 'Weight', type: FieldEnum.float, uiElement: UiElementEnum.slider, defaultValue: 60.0),
      TemplateField(id: 'f-lift-3', label: 'Reps', type: FieldEnum.integer, uiElement: UiElementEnum.stepper, defaultValue: 10),
    ],
  ),
  _template(
    id: _periodId,
    name: 'Period',
    icon: 'material:local_florist',
    emoji: '\u{1F338}',
    accents: ['#EC407A', '#F48FB1'],
    tones: ['#AD1457', '#C2185B'],
    fields: [
      TemplateField(id: 'f-per-1', label: 'Flow Intensity', type: FieldEnum.integer, uiElement: UiElementEnum.slider, defaultValue: 3, validators: [FieldValidator(validatorType: ValidatorType.numeric, validatorData: {'min': 1, 'max': 5})]),
      TemplateField(id: 'f-per-2', label: 'Cramps', type: FieldEnum.integer, uiElement: UiElementEnum.slider, defaultValue: 1, validators: [FieldValidator(validatorType: ValidatorType.numeric, validatorData: {'min': 1, 'max': 5})]),
      TemplateField(id: 'f-per-3', label: 'Notes', type: FieldEnum.text, uiElement: UiElementEnum.textArea, validators: [FieldValidator(validatorType: ValidatorType.optional, validatorData: {})]),
    ],
  ),
  _template(
    id: _waterId,
    name: 'Water',
    icon: 'material:water_drop',
    emoji: '\u{1F4A7}',
    accents: ['#29B6F6', '#4FC3F7'],
    tones: ['#0277BD', '#0288D1'],
    fields: [
      TemplateField(id: 'f-wat-1', label: 'Glasses', type: FieldEnum.integer, uiElement: UiElementEnum.stepper, defaultValue: 1),
    ],
  ),
  _template(
    id: _sleepId,
    name: 'Sleep',
    icon: 'material:bedtime',
    emoji: '\u{1F634}',
    accents: ['#5C6BC0', '#7986CB'],
    tones: ['#303F9F', '#3F51B5'],
    fields: [
      TemplateField(id: 'f-slp-1', label: 'Hours', type: FieldEnum.float, uiElement: UiElementEnum.slider, defaultValue: 8.0),
      TemplateField(id: 'f-slp-2', label: 'Quality', type: FieldEnum.enumerated, uiElement: UiElementEnum.chips, options: ['Poor', 'Fair', 'Good', 'Great'], defaultValue: 'Good'),
    ],
  ),
  _template(
    id: _emotionId,
    name: 'Emotion',
    icon: 'material:palette',
    emoji: '\u{1F3A8}',
    accents: ['#AB47BC', '#7E57C2'],
    tones: ['#6A1B9A', '#4527A0'],
    fields: [
      TemplateField(id: 'f-emo-1', label: 'Feeling', type: FieldEnum.enumerated, uiElement: UiElementEnum.chips, options: ['Happy', 'Calm', 'Anxious', 'Sad', 'Angry'], defaultValue: 'Calm'),
      TemplateField(id: 'f-emo-2', label: 'Intensity', type: FieldEnum.integer, uiElement: UiElementEnum.slider, defaultValue: 5),
    ],
  ),
  _template(
    id: _cyclingId,
    name: 'Cycling',
    icon: 'material:directions_bike',
    emoji: '\u{1F6B4}',
    accents: ['#66BB6A', '#81C784'],
    tones: ['#2E7D32', '#388E3C'],
    fields: [
      TemplateField(id: 'f-cyc-1', label: 'Distance', type: FieldEnum.float, uiElement: UiElementEnum.slider, defaultValue: 10.0),
      TemplateField(id: 'f-cyc-2', label: 'Duration', type: FieldEnum.integer, uiElement: UiElementEnum.stepper, defaultValue: 30),
    ],
  ),
  _template(
    id: _journalId,
    name: 'Journal',
    icon: 'material:auto_stories',
    emoji: '\u{1F4D3}',
    accents: ['#8D6E63', '#A1887F'],
    tones: ['#4E342E', '#5D4037'],
    fields: [
      TemplateField(id: 'f-jrn-1', label: 'Entry', type: FieldEnum.text, uiElement: UiElementEnum.textArea, defaultValue: ''),
    ],
  ),
  _template(
    id: _medicationId,
    name: 'Medication',
    icon: 'material:medication',
    emoji: '\u{1F48A}',
    accents: ['#EF5350', '#E57373'],
    tones: ['#C62828', '#D32F2F'],
    fields: [
      TemplateField(id: 'f-med-1', label: 'Taken', type: FieldEnum.boolean, uiElement: UiElementEnum.checkbox, defaultValue: true),
    ],
  ),
];

/// Returns the 8 fake templates with names/labels translated for [locale].
List<TemplateWithAesthetics> fakeTemplatesForLocale(String locale) {
  if (locale == 'en') return fakeTemplates;
  return fakeTemplates.map((twa) {
    final translatedFields = twa.template.fields.map((f) {
      return f.copyWith(
        label: tr(f.label, locale),
        options: f.options != null ? _trList(f.options!, locale) : null,
        defaultValue: f.defaultValue is String
            ? tr(f.defaultValue as String, locale)
            : f.defaultValue,
      );
    }).toList();
    return TemplateWithAesthetics(
      template: twa.template.copyWith(
        name: tr(twa.template.name, locale),
        fields: translatedFields,
      ),
      aesthetics: twa.aesthetics,
    );
  }).toList();
}

/// Templates marked as hidden (for lock/hidden screenshot).
/// Returns the same 8 templates but with 2 marked as hidden.
List<TemplateWithAesthetics> get fakeTemplatesWithHidden => [
  fakeTemplates[0], // Lifting - visible
  fakeTemplates[1], // Period - visible
  fakeTemplates[2], // Water - visible
  fakeTemplates[3], // Sleep - visible
  fakeTemplates[4], // Emotion - visible
  fakeTemplates[5], // Cycling - visible
  // Journal and Medication are hidden
  TemplateWithAesthetics(
    template: fakeTemplates[6].template.copyWith(isHidden: true),
    aesthetics: fakeTemplates[6].aesthetics,
  ),
  TemplateWithAesthetics(
    template: fakeTemplates[7].template.copyWith(isHidden: true),
    aesthetics: fakeTemplates[7].aesthetics,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Fake past timeline items (for temporal past screenshot)
// ─────────────────────────────────────────────────────────────────────────────

/// Pre-built timeline items for the past tab showing realistic log history.
/// Pass [locale] to translate template names and data previews.
List<TimelineItem> fakePastTimelineItemsForLocale([String locale = 'en']) {
  final templates = fakeTemplatesForLocale(locale);
  return _buildPastTimelineItems(templates, locale);
}

/// English-only shortcut for backwards compatibility.
List<TimelineItem> get fakePastTimelineItems => fakePastTimelineItemsForLocale();

List<TimelineItem> _buildPastTimelineItems(List<TemplateWithAesthetics> templates, String locale) {
  final today = DateTime(2026, 4, 1);
  final yesterday = DateTime(2026, 3, 31);
  final twoDaysAgo = DateTime(2026, 3, 30);

  // Use app date formatter with locale
  String date(DateTime d) => QuanityaDateFormat.monthDayCompact(d, locale);
  String time(DateTime d) => QuanityaDateFormat.time(d, locale);

  final t1 = today.add(const Duration(hours: 14, minutes: 30));
  final t2 = today.add(const Duration(hours: 7, minutes: 15));
  final t3 = yesterday.add(const Duration(hours: 18));
  final t4 = yesterday.add(const Duration(hours: 12));
  final t5 = yesterday.add(const Duration(hours: 8));
  final t6 = twoDaysAgo.add(const Duration(hours: 17, minutes: 30));
  final t7 = twoDaysAgo.add(const Duration(hours: 10));

  return [
    TimelineItem.dateDivider(dateKey: '2026-04-01', isFirst: true, formattedDate: date(today)),
    _timelineEntry(
      entryId: 'e-01', template: templates[2],
      occurredAt: t1, data: {'Glasses': 2},
      dataPreview: '2 ${tr('Glasses', locale).toLowerCase()}',
      timeString: time(t1), dateString: date(today), isFirst: true,
    ),
    _timelineEntry(
      entryId: 'e-02', template: templates[3],
      occurredAt: t2, data: {'Hours': 7.5, 'Quality': 'Great'},
      dataPreview: '7.5 ${tr('Hours', locale).toLowerCase()}',
      timeString: time(t2), dateString: date(today),
    ),
    TimelineItem.dateDivider(dateKey: '2026-03-31', isFirst: false, formattedDate: date(yesterday)),
    _timelineEntry(
      entryId: 'e-03', template: templates[0],
      occurredAt: t3, data: {'Exercise': 'Deadlift', 'Weight': 100.0, 'Reps': 5},
      dataPreview: tr('Deadlift', locale),
      timeString: time(t3), dateString: date(yesterday),
    ),
    _timelineEntry(
      entryId: 'e-04', template: templates[4],
      occurredAt: t4, data: {'Feeling': 'Happy', 'Intensity': 8},
      dataPreview: tr('Happy', locale),
      timeString: time(t4), dateString: date(yesterday),
    ),
    _timelineEntry(
      entryId: 'e-05', template: templates[7],
      occurredAt: t5, data: {'Taken': true},
      dataPreview: tr('Taken', locale),
      timeString: time(t5), dateString: date(yesterday),
    ),
    TimelineItem.dateDivider(dateKey: '2026-03-30', isFirst: false, formattedDate: date(twoDaysAgo)),
    _timelineEntry(
      entryId: 'e-06', template: templates[5],
      occurredAt: t6, data: {'Distance': 15.2, 'Duration': 42},
      dataPreview: '15.2 km',
      timeString: time(t6), dateString: date(twoDaysAgo),
    ),
    _timelineEntry(
      entryId: 'e-07', template: templates[2],
      occurredAt: t7, data: {'Glasses': 3},
      dataPreview: '3 ${tr('Glasses', locale).toLowerCase()}',
      timeString: time(t7), dateString: date(twoDaysAgo), isLast: true,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake future schedules (for temporal future screenshot)
// ─────────────────────────────────────────────────────────────────────────────

/// Pre-built schedule list, localized.
List<ScheduleWithContext> fakeSchedulesForLocale([String locale = 'en']) {
  final templates = fakeTemplatesForLocale(locale);
  return _buildSchedules(templates);
}

/// English-only shortcut.
List<ScheduleWithContext> get fakeSchedules => fakeSchedulesForLocale();

List<ScheduleWithContext> _buildSchedules(List<TemplateWithAesthetics> templates) {
  final now = DateTime(2026, 4, 1);
  return [
    ScheduleWithContext(
      schedule: ScheduleModel(
        id: 's-01',
        templateId: _waterId,
        recurrenceRule: 'FREQ=DAILY;BYHOUR=9;BYMINUTE=0',
        reminderOffsetMinutes: 0,
        isActive: true,
        lastGeneratedAt: now,
        updatedAt: now,
      ),
      template: templates[2].template,
      aesthetics: templates[2].aesthetics,
    ),
    ScheduleWithContext(
      schedule: ScheduleModel(
        id: 's-02',
        templateId: _medicationId,
        recurrenceRule: 'FREQ=DAILY;BYHOUR=8;BYMINUTE=0',
        reminderOffsetMinutes: 15,
        isActive: true,
        lastGeneratedAt: now,
        updatedAt: now,
      ),
      template: templates[7].template,
      aesthetics: templates[7].aesthetics,
    ),
    ScheduleWithContext(
      schedule: ScheduleModel(
        id: 's-03',
        templateId: _liftingId,
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=18;BYMINUTE=0',
        reminderOffsetMinutes: 30,
        isActive: true,
        lastGeneratedAt: now,
        updatedAt: now,
      ),
      template: templates[0].template,
      aesthetics: templates[0].aesthetics,
    ),
    ScheduleWithContext(
      schedule: ScheduleModel(
        id: 's-04',
        templateId: _sleepId,
        recurrenceRule: 'FREQ=DAILY;BYHOUR=22;BYMINUTE=0',
        reminderOffsetMinutes: 0,
        isActive: true,
        lastGeneratedAt: now,
        updatedAt: now,
      ),
      template: templates[3].template,
      aesthetics: templates[3].aesthetics,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake results data (for graph/analysis screenshots)
// ─────────────────────────────────────────────────────────────────────────────

/// Results template items for the Results tab folds.
List<ResultsTemplateItem> get fakeResultsTemplates => [
  ResultsTemplateItem(
    templateId: _waterId,
    templateName: 'Water',
    entryCount: 30,
    lastLoggedAt: DateTime(2026, 4, 1),
    hasGraphableFields: true,
    hasAnalyzableFields: false,
    icon: 'material:water_drop',
    emoji: '\u{1F4A7}',
    accentColorHex: '#29B6F6',
  ),
  ResultsTemplateItem(
    templateId: _liftingId,
    templateName: 'Lifting',
    entryCount: 10,
    lastLoggedAt: DateTime(2026, 3, 31),
    hasGraphableFields: true,
    hasAnalyzableFields: true,
    icon: 'material:fitness_center',
    emoji: '\u{1F4AA}',
    accentColorHex: '#78909C',
  ),
  ResultsTemplateItem(
    templateId: _sleepId,
    templateName: 'Sleep',
    entryCount: 28,
    lastLoggedAt: DateTime(2026, 4, 1),
    hasGraphableFields: true,
    hasAnalyzableFields: false,
    icon: 'material:bedtime',
    emoji: '\u{1F634}',
    accentColorHex: '#5C6BC0',
  ),
  ResultsTemplateItem(
    templateId: _emotionId,
    templateName: 'Emotion',
    entryCount: 22,
    lastLoggedAt: DateTime(2026, 3, 30),
    hasGraphableFields: true,
    hasAnalyzableFields: false,
    icon: 'material:palette',
    emoji: '\u{1F3A8}',
    accentColorHex: '#AB47BC',
  ),
];

/// Fake water chart data — 30 daily entries of cups consumed (4–9 range).
/// Mimics the dev seeder water generator.
TemplateAggregatedData get fakeWaterChartData {
  final cupsField = TemplateField(
    id: 'f-wat-1',
    label: 'Glasses',
    type: FieldEnum.integer,
    defaultValue: 1,
  );

  final random = [6, 8, 5, 7, 9, 4, 6, 8, 7, 5, 9, 6, 4, 7, 8, 5, 6, 9, 7, 4, 8, 6, 5, 7, 9, 8, 4, 6, 7, 5];
  final points = <({DateTime date, num value})>[];
  final loggedDates = <DateTime>[];
  for (var i = 0; i < 30; i++) {
    final date = DateTime(2026, 4, 1).subtract(Duration(days: i));
    points.add((date: date, value: random[i]));
    loggedDates.add(date);
  }

  return TemplateAggregatedData(
    template: fakeTemplates[2].template, // Water
    numericFields: [NumericFieldData(field: cupsField, points: points)],
    booleanFields: [],
    categoricalFields: [],
    locationFields: [],
    totalEntries: 30,
    completedEntries: 30,
    startDate: DateTime(2026, 3, 3),
    endDate: DateTime(2026, 4, 1),
    loggedDates: loggedDates,
  );
}

/// Fake lifting chart data — weight and reps over 10 sessions.
/// Mimics the dev seeder lifting generator.
TemplateAggregatedData get fakeLiftingChartData {
  final weightField = TemplateField(
    id: 'f-lift-2',
    label: 'Weight',
    type: FieldEnum.float,
    defaultValue: 60.0,
  );
  final repsField = TemplateField(
    id: 'f-lift-3',
    label: 'Reps',
    type: FieldEnum.integer,
    defaultValue: 10,
  );

  final weightValues = [55.0, 57.5, 60.0, 60.0, 62.5, 60.0, 65.0, 62.5, 67.5, 70.0];
  final repsValues = [10, 8, 10, 12, 8, 10, 6, 8, 6, 5];
  final weightPoints = <({DateTime date, num value})>[];
  final repsPoints = <({DateTime date, num value})>[];
  final loggedDates = <DateTime>[];

  for (var i = 0; i < 10; i++) {
    final date = DateTime(2026, 4, 1).subtract(Duration(days: i * 2));
    weightPoints.add((date: date, value: weightValues[i]));
    repsPoints.add((date: date, value: repsValues[i]));
    loggedDates.add(date);
  }

  return TemplateAggregatedData(
    template: fakeTemplates[0].template, // Lifting
    numericFields: [
      NumericFieldData(field: weightField, points: weightPoints),
      NumericFieldData(field: repsField, points: repsPoints),
    ],
    booleanFields: [],
    categoricalFields: [],
    locationFields: [],
    totalEntries: 10,
    completedEntries: 10,
    startDate: DateTime(2026, 3, 13),
    endDate: DateTime(2026, 4, 1),
    loggedDates: loggedDates,
  );
}

/// Fake analysis results for Lifting — volume calculation results.
/// Mocks what the JS WASM analysis engine would return.
Map<String, ScriptResult> get fakeLiftingAnalysisResults {
  final script = AnalysisScriptModel(
    id: 'script-lift-volume',
    name: 'Volume Analysis',
    templateId: _liftingId,
    fieldId: 'f-lift-2',
    outputMode: AnalysisOutputMode.scalar,
    snippetLanguage: AnalysisSnippetLanguage.js,
    snippet: '',
    updatedAt: DateTime(2026, 4, 1),
  );

  return {
    'script-lift-volume': ScriptResult(
      script: script,
      result: AnalysisOutput.scalar([
        AnalysisScalar(label: 'Avg Weight', value: 62.0, unit: 'kg'),
        AnalysisScalar(label: 'Max Weight', value: 70.0, unit: 'kg'),
        AnalysisScalar(label: 'Total Volume', value: 5240.0, unit: 'kg'),
        AnalysisScalar(label: 'Avg Reps', value: 8.3, unit: 'reps'),
        AnalysisScalar(label: 'Sessions', value: 10.0, unit: ''),
      ]),
    ),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Helper to build a [TemplateWithAesthetics] with minimal boilerplate.
TemplateWithAesthetics _template({
  required String id,
  required String name,
  required String icon,
  required String emoji,
  required List<String> accents,
  required List<String> tones,
  List<TemplateField> fields = const [],
}) {
  final now = DateTime(2026, 1, 1);
  return TemplateWithAesthetics(
    template: TrackerTemplateModel(
      id: id,
      name: name,
      fields: fields,
      updatedAt: now,
      isArchived: false,
      isHidden: false,
    ),
    aesthetics: TemplateAestheticsModel.create(
      templateId: id,
      icon: icon,
      emoji: emoji,
      palette: ColorPaletteData(accents: accents, tones: tones),
      fontConfig: FontConfigData.defaults(),
    ),
  );
}

/// Helper to build a single timeline entry item.
TimelineItem _timelineEntry({
  required String entryId,
  required TemplateWithAesthetics template,
  required DateTime occurredAt,
  required Map<String, dynamic> data,
  required String dataPreview,
  required String timeString,
  required String dateString,
  bool isFirst = false,
  bool isLast = false,
}) {
  return TimelineItem.entry(
    entryWithContext: LogEntryWithContext(
      entry: LogEntryModel(
        id: entryId,
        templateId: template.template.id,
        occurredAt: occurredAt,
        data: data,
        updatedAt: occurredAt,
      ),
      template: template.template,
      aesthetics: template.aesthetics,
    ),
    isFirst: isFirst,
    isLast: isLast,
    showTimeOnly: true,
    timeString: timeString,
    dateString: dateString,
    dataPreview: dataPreview,
    iconString: template.aesthetics.icon,
    emoji: template.aesthetics.emoji,
    accentColorHex: template.aesthetics.palette.accents.firstOrNull,
  );
}
