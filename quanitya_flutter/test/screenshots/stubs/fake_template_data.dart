/// Fake template data for golden screenshot tests.
///
/// Provides 8 realistic templates so the home screen renders populated cards
/// instead of an empty state.
library;

import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart'
    show TemplateWithAesthetics;
import 'package:quanitya_flutter/logic/templates/models/shared/template_aesthetics.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

/// Eight templates matching the dev_templates catalog, with exact aesthetics.
final List<TemplateWithAesthetics> fakeTemplates = [
  _template(
    id: '00000000-0000-0000-0000-000000000001',
    name: 'Lifting',
    icon: 'material:fitness_center',
    emoji: '\u{1F4AA}',
    accents: ['#78909C', '#90A4AE'],
    tones: ['#37474F', '#455A64'],
  ),
  _template(
    id: '00000000-0000-0000-0000-000000000002',
    name: 'Period',
    icon: 'material:local_florist',
    emoji: '\u{1F338}',
    accents: ['#EC407A', '#F48FB1'],
    tones: ['#AD1457', '#C2185B'],
  ),
  _template(
    id: '00000000-0000-0000-0000-000000000003',
    name: 'Water',
    icon: 'material:water_drop',
    emoji: '\u{1F4A7}',
    accents: ['#29B6F6', '#4FC3F7'],
    tones: ['#0277BD', '#0288D1'],
  ),
  _template(
    id: '00000000-0000-0000-0000-000000000004',
    name: 'Sleep',
    icon: 'material:bedtime',
    emoji: '\u{1F634}',
    accents: ['#5C6BC0', '#7986CB'],
    tones: ['#303F9F', '#3F51B5'],
  ),
  _template(
    id: '00000000-0000-0000-0000-000000000005',
    name: 'Emotion',
    icon: 'material:palette',
    emoji: '\u{1F3A8}',
    accents: ['#AB47BC', '#7E57C2'],
    tones: ['#6A1B9A', '#4527A0'],
  ),
  _template(
    id: '00000000-0000-0000-0000-000000000006',
    name: 'Cycling',
    icon: 'material:directions_bike',
    emoji: '\u{1F6B4}',
    accents: ['#66BB6A', '#81C784'],
    tones: ['#2E7D32', '#388E3C'],
  ),
  _template(
    id: '00000000-0000-0000-0000-000000000007',
    name: 'Journal',
    icon: 'material:auto_stories',
    emoji: '\u{1F4D3}',
    accents: ['#8D6E63', '#A1887F'],
    tones: ['#4E342E', '#5D4037'],
  ),
  _template(
    id: '00000000-0000-0000-0000-000000000008',
    name: 'Medication',
    icon: 'material:medication',
    emoji: '\u{1F48A}',
    accents: ['#EF5350', '#E57373'],
    tones: ['#C62828', '#D32F2F'],
  ),
];

/// Helper to build a [TemplateWithAesthetics] with minimal boilerplate.
TemplateWithAesthetics _template({
  required String id,
  required String name,
  required String icon,
  required String emoji,
  required List<String> accents,
  required List<String> tones,
}) {
  final now = DateTime(2026, 1, 1);
  return TemplateWithAesthetics(
    template: TrackerTemplateModel(
      id: id,
      name: name,
      fields: [],
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
