# Localization Setup

This directory contains the Flutter l10n (localization) configuration and translation files for the Quanitya app.

## Files

- **`app_en.arb`** - English translations (source of truth)
- **`app_localizations.dart`** - Generated base class (auto-generated, do not edit)
- **`app_localizations_en.dart`** - Generated English implementation (auto-generated, do not edit)

## Current Messages

### Generic UI Messages
- Success, error, and loading messages
- Validation messages (required, invalid format, too short, too long)
- Navigation labels (dashboard, templates, settings)
- Action labels (save, cancel, delete, edit, add)

### Template Generation Messages
- Success messages for generation, regeneration, preview, validation
- Loading messages for all operations
- Error messages for validation, AI service, schema validation, performance, processing
- Performance warnings and retry attempt notifications

### Template Parsing Messages
- Missing field, invalid value, invalid combination errors
- Color palette and color mapping errors
- Generic parsing errors

### Template Rendering Messages
- Context creation, color resolution, validation errors
- Widget creation, accessibility, layout errors

### Accessibility Messages
- Adjustment notifications
- Contrast ratio, color blindness, focus indicator issues
- Touch target size and text readability problems

## Adding New Translations

### 1. Add to ARB File

Edit `app_en.arb` and add your new message:

```json
{
  "myNewMessage": "This is my new message",
  "@myNewMessage": {
    "description": "Description of what this message is for"
  }
}
```

### 2. With Parameters

For messages with dynamic values:

```json
{
  "welcomeUser": "Welcome, {userName}!",
  "@welcomeUser": {
    "description": "Welcome message with user name",
    "placeholders": {
      "userName": {
        "type": "String",
        "description": "The user's name"
      }
    }
  }
}
```

### 3. Regenerate

Run the code generator:

```bash
flutter gen-l10n
```

### 4. Update AppLocalizationService

Add the new key to the `translate()` method in `lib/core/services/localization_service.dart`:

```dart
return switch (key) {
  // ... existing keys
  'my.new.message' => l10n.myNewMessage,
  _ => key,
};
```

For parameterized messages, add to `_handleParameterizedMessage()`:

```dart
String _handleParameterizedMessage(String key, Map<String, dynamic> args, AppLocalizations l10n) {
  return switch (key) {
    // ... existing keys
    'welcome.user' => l10n.welcomeUser(args['userName'] as String? ?? ''),
    _ => key,
  };
}
```

## Adding New Languages

### 1. Create New ARB File

Create `app_<locale>.arb` (e.g., `app_es.arb` for Spanish):

```json
{
  "@@locale": "es",
  "successGeneric": "¡Éxito!",
  "errorGeneric": "Ocurrió un error",
  // ... translate all messages
}
```

### 2. Update Supported Locales

In `lib/main.dart`, add the new locale:

```dart
supportedLocales: const [
  Locale('en'), // English
  Locale('es'), // Spanish
],
```

### 3. Regenerate

```bash
flutter gen-l10n
```

## Usage in Code

### Simple Messages

```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.successGeneric); // "Success!"
```

### Through Cubit UI Flow

The localization service is automatically integrated with the Cubit UI Flow system:

```dart
// In your message mapper
MessageKey.success('template.generation.success')

// Automatically translates to: "Template generated successfully!"
```

### Parameterized Messages

```dart
// Through the localization service
getIt<AppLocalizationService>().translate(
  'template.generation.performance_warning',
  args: {'timeMs': 2500, 'suggestion': 'Reduce field count'},
);
// Result: "Generation took longer than expected (2500ms). Consider: Reduce field count"
```

## Configuration Files

- **`l10n.yaml`** - Configuration for the l10n code generator
- **`pubspec.yaml`** - Includes `flutter_localizations` and `generate: true`

## Best Practices

1. **Always add descriptions** - Use `@messageName` to document what each message is for
2. **Use placeholders** - For dynamic content, use placeholders instead of string concatenation
3. **Keep keys organized** - Use dot notation for namespacing (e.g., `template.generation.success`)
4. **Test all languages** - When adding new languages, test that all messages are translated
5. **Regenerate after changes** - Always run `flutter gen-l10n` after modifying ARB files

## Integration with Error Handling

The template generator error handling system is fully integrated with l10n:

- **TemplateGenerationMessageMapper** - Maps generation states to message keys
- **TemplateExceptionMapper** - Maps exceptions to user-friendly error messages
- **AppLocalizationService** - Translates keys to localized strings
- **Cubit UI Flow** - Automatically displays translated messages as toasts/overlays

This creates a seamless flow from error → message key → translation → UI feedback!