import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/model_runtime_converter.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_aesthetics.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

void main() {
  late ModelRuntimeConverter converter;

  setUp(() {
    converter = ModelRuntimeConverter();
  });

  group('toColorPalette', () {
    test('converts hex strings to Colors', () {
      final palette = ColorPaletteData(
        accents: ['#1976D2', '#388E3C'],
        tones: ['#212121', '#F5F5F5'],
      );

      final appPalette = converter.toColorPalette(palette);

      // accents map to color1, color2, etc.
      expect(appPalette.getColor('color1'), const Color(0xFF1976D2));
      expect(appPalette.getColor('color2'), const Color(0xFF388E3C));
      // tones map to neutral1, neutral2, etc.
      expect(appPalette.getColor('neutral1'), const Color(0xFF212121));
      expect(appPalette.getColor('neutral2'), const Color(0xFFF5F5F5));
    });

    test('handles lowercase hex colors', () {
      final palette = ColorPaletteData(
        accents: ['#1976d2'],
        tones: ['#212121'],
      );

      final appPalette = converter.toColorPalette(palette);

      expect(appPalette.getColor('color1'), const Color(0xFF1976D2));
    });
  });

  group('toFontsConfig', () {
    test('preserves all properties', () {
      final fontConfig = FontConfigData(
        titleFontFamily: 'Roboto',
        subtitleFontFamily: 'Open Sans',
        bodyFontFamily: 'Lato',
        titleWeight: 700,
        subtitleWeight: 500,
        bodyWeight: 400,
      );

      final fontsConfig = converter.toFontsConfig(fontConfig);

      expect(fontsConfig.titleFontFamily, 'Roboto');
      expect(fontsConfig.subtitleFontFamily, 'Open Sans');
      expect(fontsConfig.bodyFontFamily, 'Lato');
      expect(fontsConfig.titleWeight, 700);
      expect(fontsConfig.subtitleWeight, 500);
      expect(fontsConfig.bodyWeight, 400);
    });

    test('provides FontWeight getters', () {
      final fontConfig = FontConfigData(
        titleWeight: 700,
        subtitleWeight: 500,
        bodyWeight: 400,
      );

      final fontsConfig = converter.toFontsConfig(fontConfig);

      expect(fontsConfig.titleFontWeight, FontWeight.w700);
      expect(fontsConfig.subtitleFontWeight, FontWeight.w500);
      expect(fontsConfig.bodyFontWeight, FontWeight.w400);
    });

    test('handles default values', () {
      final fontConfig = FontConfigData.defaults();

      final fontsConfig = converter.toFontsConfig(fontConfig);

      expect(fontsConfig.titleWeight, 600);
      expect(fontsConfig.subtitleWeight, 400);
      expect(fontsConfig.bodyWeight, 400);
    });
  });

  group('resolveColor', () {
    late ColorPaletteData palette;

    setUp(() {
      palette = ColorPaletteData(
        accents: ['#1976D2', '#388E3C', '#F57C00'],
        tones: ['#212121', '#F5F5F5'],
      );
    });

    test('returns correct Color for valid accent slot', () {
      // accent1, accent2, accent3 map to the accents array
      expect(
          converter.resolveColor(palette, 'accent1'), const Color(0xFF1976D2));
      expect(
          converter.resolveColor(palette, 'accent2'), const Color(0xFF388E3C));
      expect(
          converter.resolveColor(palette, 'accent3'), const Color(0xFFF57C00));
    });

    test('returns correct Color for valid tone slot', () {
      // tone1, tone2 map to the tones array
      expect(converter.resolveColor(palette, 'tone1'), const Color(0xFF212121));
      expect(converter.resolveColor(palette, 'tone2'), const Color(0xFFF5F5F5));
    });

    test('returns null for invalid slot', () {
      expect(converter.resolveColor(palette, 'accent99'), isNull);
      expect(converter.resolveColor(palette, 'invalid'), isNull);
    });
  });

  group('resolveWidgetColors', () {
    late TemplateAestheticsModel aesthetics;

    setUp(() {
      aesthetics = TemplateAestheticsModel.create(
        templateId: 'test-template-id',
        emoji: '🏋️',
        palette: ColorPaletteData(
          accents: ['#1976D2', '#388E3C', '#F57C00'],
          tones: ['#212121', '#F5F5F5'],
        ),
        fontConfig: FontConfigData.defaults(),
        colorMappings: {
          'slider': {
            'trackColor': 'accent1',
            'thumbColor': 'accent2',
          },
          'stepper': {
            'buttonColor': 'accent1',
            'textColor': 'tone1',
          },
        },
      );
    });

    test('returns resolved colors for valid widget', () {
      final sliderColors = converter.resolveWidgetColors(aesthetics, 'slider');

      expect(sliderColors, isNotNull);
      expect(sliderColors!['trackColor'], const Color(0xFF1976D2));
      expect(sliderColors['thumbColor'], const Color(0xFF388E3C));
    });

    test('returns null for unknown widget', () {
      expect(converter.resolveWidgetColors(aesthetics, 'unknownWidget'), isNull);
    });

    test('handles mixed color slots', () {
      final stepperColors =
          converter.resolveWidgetColors(aesthetics, 'stepper');

      expect(stepperColors, isNotNull);
      expect(stepperColors!['buttonColor'], const Color(0xFF1976D2));
      expect(stepperColors['textColor'], const Color(0xFF212121));
    });
  });

  group('toPageConfig', () {
    test('uses template name as title and aesthetics emoji', () {
      final template = TrackerTemplateModel.create(
        name: 'Weight Tracker',
        fields: [],
      );
      final aesthetics = TemplateAestheticsModel.create(
        templateId: template.id,
        emoji: '🏋️',
        palette: ColorPaletteData.defaults(),
        fontConfig: FontConfigData.defaults(),
      );

      final pageConfig = converter.toPageConfig(template, aesthetics);

      expect(pageConfig.title, 'Weight Tracker');
      expect(pageConfig.iconEmoji, '🏋️');
    });

    test('handles null emoji with default', () {
      final template = TrackerTemplateModel.create(
        name: 'Mood Log',
        fields: [],
      );
      final aesthetics = TemplateAestheticsModel.create(
        templateId: template.id,
        palette: ColorPaletteData.defaults(),
        fontConfig: FontConfigData.defaults(),
      );

      final pageConfig = converter.toPageConfig(template, aesthetics);

      expect(pageConfig.title, 'Mood Log');
      expect(pageConfig.iconEmoji, '📝'); // Default emoji
    });
  });
}
