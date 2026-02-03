---
inclusion: always
---
# Quanitya Custom Libraries (Concise)

## 1. dart_jwk_duo - E2EE Key Management
**Purpose:** Type-safe cryptographic key pairs for E2EE

```dart
// Two key pairs per user:
// - SigningKeyPair (ECDSA P-256) → Identity, auth tokens
// - EncryptionKeyPair (RSA-OAEP-256) → Data protection

// Usage in CryptoService:
final signature = await keyDuo.signingKeyPair.signBytes(challenge);
final encrypted = await keyDuo.encryptionKeyPair.encryptBytes(data);
```

## 2. cubit_ui_flow - State → UI Feedback
**Purpose:** Automatic loading/error/success handling

```dart
// State implements IUiFlowState
@freezed
class MyState with _$MyState implements IUiFlowState {
  const factory MyState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    MyOperation? lastOperation,
  }) = _MyState;
}

// Cubit extends QuanityaCubit
await tryOperation(() async {
  await repo.save();
  return state.copyWith(status: UiFlowStatus.success, lastOperation: MyOperation.save);
}, emitLoading: true);

// UI wraps with UiFlowListener
UiFlowListener<MyCubit, MyState>(
  mapper: MyMessageMapper(),
  child: MyWidget(),
)
```

## 3. flutter_color_palette - Theming
**Purpose:** Enumerated colors with automatic dark mode

```dart
// Access via QuanityaPalette.primary
palette.textPrimary       // #121212
palette.textSecondary     // #5A5A5A
palette.interactableColor // #006280 (teal)
palette.successColor      // #2E7D32
palette.errorColor        // #B33B28
palette.backgroundPrimary // #F9F7F2

// Dark mode: palette.symmetricPalette (auto-inverted)
```

## 4. dart_l10n_key_resolver - Localization
**Purpose:** Dot-notation keys → ARB camelCase getters

```dart
// In ARB file (camelCase):
"templateSaved": "Template saved"
"errorAuthFailed": "Authentication failed"

// In code (dot-notation):
MessageKey.success('template.saved')  // → templateSaved
MessageKey.error('error.auth.failed') // → errorAuthFailed

// Generated L10nKeyResolver handles conversion automatically
// Run: dart run build_runner build --delete-conflicting-outputs
```

## 5. flutter_error_privserver - Privacy-First Error Reporting
**Purpose:** User-controlled error reporting with zero PII capture

```dart
// QuanityaCubit already includes ErrorPrivserverMixin - no changes needed!
// All cubits automatically capture errors when using tryOperation()

// What gets captured (PII-free by design):
// - Error types: NetworkException, ValidationException
// - Cubit names: TemplateListCubit, AccountCubit
// - Error codes: NET_001, VAL_002
// - Stack traces: Complete call chains (no function arguments)

// What NEVER gets captured:
// - User input, form data, emails, passwords
// - Exception messages with potential PII
// - Function arguments or variable values

// Users review and send errors from Settings → Error Reports
// Never auto-sends - always requires explicit user consent
```

## Key Integration Points

| Library | Used By | Purpose |
|---------|---------|---------|
| dart_jwk_duo | CryptoKeyRepository, AuthService | E2EE encryption |
| cubit_ui_flow | All Cubits, UiFlowListener | Auto UI feedback |
| flutter_color_palette | QuanityaPalette, all widgets | Consistent theming |
| dart_l10n_key_resolver | AppLocalizationService | Key resolution |
| flutter_error_privserver | QuanityaCubit (automatic) | Privacy-safe error capture |
