import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';

import 'package:quanitya_flutter/design_system/theme/theme_service.dart';
import 'package:quanitya_flutter/design_system/primitives/quanitya_palette.dart';
import 'package:quanitya_flutter/logic/templates/models/engine/page_configuration.dart';

void main() {
  group('ThemeService AI Theme Integration', () {
    late ThemeService themeService;
    late IColorPalette testPalette;
    late FontsConfig testFonts;

    setUp(() {
      themeService = ThemeService();
      
      // Create test color palette matching QuanityaColors extension expectations
      testPalette = AppColorPalette(
        colors: {
          'color1': const Color(0xFFF5F5F5), // Light - background
          'color2': const Color(0xFF212121), // Dark - text primary
          'color3': const Color(0xFF1976D2), // Blue - primary/accent
          'neutral1': const Color(0xFF757575), // Medium - text secondary
          'interactable': const Color(0xFF1976D2), // Blue - interactable
          'info': const Color(0xFF2196F3),     // Blue - info
          'error': const Color(0xFFD32F2F),    // Red - error
          'success': const Color(0xFF388E3C),  // Green - success
          'warning': const Color(0xFFF57C00),  // Orange - warning
          'destructive': const Color(0xFFD32F2F), // Red - destructive
        },
        name: 'Test Palette',
      );
      
      // Create test font configuration
      testFonts = const FontsConfig(
        titleFontFamily: 'Roboto',
        subtitleFontFamily: 'Open Sans',
        bodyFontFamily: 'Lato',
        titleWeight: 700,
        subtitleWeight: 500,
        bodyWeight: 400,
      );
    });

    group('buildAiTheme()', () {
      test('should create theme with AI-generated palette', () {
        // Act
        final theme = themeService.buildAiTheme(
          colorPalette: testPalette,
        );

        // Assert
        expect(theme.colorScheme.primary, equals(testPalette.primaryColor));
        expect(theme.colorScheme.secondary, equals(testPalette.secondaryColor));
        expect(theme.colorScheme.error, equals(testPalette.errorColor));
        expect(theme.colorScheme.surface, equals(testPalette.backgroundPrimary));
        expect(theme.brightness, equals(Brightness.light));
      });

      test('should create dark theme when isDark is true', () {
        // Act
        final theme = themeService.buildAiTheme(
          colorPalette: testPalette,
          isDark: true,
        );

        // Assert
        expect(theme.brightness, equals(Brightness.dark));
        expect(theme.colorScheme.brightness, equals(Brightness.dark));
      });

      test('should apply AI font configuration to text theme', () {
        // Act
        final theme = themeService.buildAiTheme(
          colorPalette: testPalette,
          fonts: testFonts,
        );

        // Assert - Title styles
        expect(theme.textTheme.headlineLarge?.fontFamily, equals('Roboto'));
        expect(theme.textTheme.headlineLarge?.fontWeight, equals(FontWeight.w700));
        expect(theme.textTheme.headlineMedium?.fontFamily, equals('Roboto'));
        expect(theme.textTheme.headlineSmall?.fontFamily, equals('Roboto'));

        // Assert - Subtitle styles
        expect(theme.textTheme.titleLarge?.fontFamily, equals('Open Sans'));
        expect(theme.textTheme.titleLarge?.fontWeight, equals(FontWeight.w500));
        expect(theme.textTheme.titleMedium?.fontFamily, equals('Open Sans'));
        expect(theme.textTheme.titleSmall?.fontFamily, equals('Open Sans'));

        // Assert - Body styles
        expect(theme.textTheme.bodyLarge?.fontFamily, equals('Lato'));
        expect(theme.textTheme.bodyLarge?.fontWeight, equals(FontWeight.w400));
        expect(theme.textTheme.bodyMedium?.fontFamily, equals('Lato'));
        expect(theme.textTheme.bodySmall?.fontFamily, equals('Lato'));
      });

      test('should use default text theme when fonts is null', () {
        // Act
        final theme = themeService.buildAiTheme(
          colorPalette: testPalette,
          fonts: null,
        );

        // Assert - Should use default theme fonts
        final defaultTheme = ThemeData.light().textTheme;
        expect(theme.textTheme.bodyLarge?.fontFamily, equals(defaultTheme.bodyLarge?.fontFamily));
        expect(theme.textTheme.headlineLarge?.fontFamily, equals(defaultTheme.headlineLarge?.fontFamily));
      });

      test('should configure component themes with AI colors', () {
        // Act
        final theme = themeService.buildAiTheme(
          colorPalette: testPalette,
        );

        // Assert - ElevatedButton theme
        expect(
          theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
          equals(testPalette.primaryColor),
        );

        // Assert - Card theme
        expect(theme.cardTheme.color, equals(testPalette.backgroundPrimary));

        // Assert - AppBar theme
        expect(theme.appBarTheme.backgroundColor, equals(testPalette.primaryColor));

        // Assert - InputDecoration theme
        expect(
          theme.inputDecorationTheme.focusedBorder?.borderSide.color,
          equals(testPalette.primaryColor),
        );
        expect(
          theme.inputDecorationTheme.errorBorder?.borderSide.color,
          equals(testPalette.errorColor),
        );
      });
    });

    group('Theme Application to Widgets', () {
      testWidgets('should apply AI theme to widgets correctly', (tester) async {
        // Arrange
        final aiTheme = themeService.buildAiTheme(
          colorPalette: testPalette,
          fonts: testFonts,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            theme: aiTheme,
            home: Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: Column(
                children: [
                  Text('Headline', style: aiTheme.textTheme.headlineLarge),
                  Text('Title', style: aiTheme.textTheme.titleLarge),
                  Text('Body', style: aiTheme.textTheme.bodyLarge),
                  ElevatedButton(onPressed: () {}, child: const Text('Button')),
                  const Card(child: Text('Card')),
                ],
              ),
            ),
          ),
        );

        // Assert - Find widgets and verify they exist
        expect(find.text('Test'), findsOneWidget);
        expect(find.text('Headline'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Body'), findsOneWidget);
        expect(find.text('Button'), findsOneWidget);
        expect(find.text('Card'), findsOneWidget);

        // Verify theme is applied
        final context = tester.element(find.text('Headline'));
        final appliedTheme = Theme.of(context);
        expect(appliedTheme.colorScheme.primary, equals(testPalette.primaryColor));
      });

      testWidgets('should inherit AI theme to child widgets', (tester) async {
        // Arrange
        final aiTheme = themeService.buildAiTheme(
          colorPalette: testPalette,
          fonts: testFonts,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            theme: aiTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  // Child widget should inherit the theme
                  return Column(
                    children: [
                      Container(
                        color: Theme.of(context).colorScheme.primary,
                        child: Text(
                          'Child Widget',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Assert - Verify child widget inherits theme
        expect(find.text('Child Widget'), findsOneWidget);
        
        final context = tester.element(find.text('Child Widget'));
        final inheritedTheme = Theme.of(context);
        
        // Verify inherited theme properties
        expect(inheritedTheme.colorScheme.primary, equals(testPalette.primaryColor));
        expect(inheritedTheme.textTheme.headlineLarge?.fontFamily, equals('Roboto'));
        expect(inheritedTheme.textTheme.headlineLarge?.fontWeight, equals(FontWeight.w700));
      });
    });

    group('Font Weight Conversion', () {
      test('should handle various font weight values correctly', () {
        // Arrange
        final fontsWithDifferentWeights = const FontsConfig(
          titleFontFamily: 'Roboto',
          subtitleFontFamily: 'Open Sans',
          bodyFontFamily: 'Lato',
          titleWeight: 900,
          subtitleWeight: 300,
          bodyWeight: 100,
        );

        // Act
        final theme = themeService.buildAiTheme(
          colorPalette: testPalette,
          fonts: fontsWithDifferentWeights,
        );

        // Assert
        expect(theme.textTheme.headlineLarge?.fontWeight, equals(FontWeight.w900));
        expect(theme.textTheme.titleLarge?.fontWeight, equals(FontWeight.w300));
        expect(theme.textTheme.bodyLarge?.fontWeight, equals(FontWeight.w100));
      });

      test('should fallback to default weights for invalid values', () {
        // Arrange
        final fontsWithInvalidWeights = const FontsConfig(
          titleFontFamily: 'Roboto',
          subtitleFontFamily: 'Open Sans',
          bodyFontFamily: 'Lato',
          titleWeight: 999, // Invalid weight
          subtitleWeight: 1,   // Invalid weight
          bodyWeight: 450,     // Invalid weight
        );

        // Act
        final theme = themeService.buildAiTheme(
          colorPalette: testPalette,
          fonts: fontsWithInvalidWeights,
        );

        // Assert - Should fallback to default weights
        expect(theme.textTheme.headlineLarge?.fontWeight, equals(FontWeight.w600)); // Default for title
        expect(theme.textTheme.titleLarge?.fontWeight, equals(FontWeight.w400));    // Default for subtitle
        expect(theme.textTheme.bodyLarge?.fontWeight, equals(FontWeight.w400));     // Default for body
      });
    });
  });
}