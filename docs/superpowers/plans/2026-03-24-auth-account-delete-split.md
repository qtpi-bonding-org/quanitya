# Auth / Account / Delete Service Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the AuthService → AuthService + AccountService + DeleteService split, add temporary ultimate key session to CryptoKeyRepository, and wire all callers correctly.

**Architecture:** AuthService becomes pure JWT session management. AccountService owns all account lifecycle + device management. DeleteService owns destructive operations (server-side delete + local factory reset). CryptoKeyRepository gains a temporary ultimate key session for operations like device revocation that need ultimate key proof.

**Tech Stack:** Flutter, Dart, injectable/GetIt DI, cubit_ui_flow, tryMethod/tryOperation error handling, SecurePreferences, CryptoKeyRepository

---

## Current State

- `AuthService` (1067 lines) — monolith with auth + account + device management + recovery + delete methods
- `AccountService` (539 lines) — exists with correct implementations but only partially wired (OnboardingCubit, RecoveryKeyCubit use it; DeviceManagementCubit partially uses it)
- `AuthRepository` (100 lines) — exists, used by AccountService
- No `DeleteService` exists
- No temporary ultimate key mechanism exists
- `ensureAuthenticated` retry logic already calls `_accountService.ensureRegistered`

## File Structure

### New Files
- `lib/infrastructure/auth/delete_service.dart` — DeleteService (server-side delete + local factory reset)

### Modified Files
- `lib/infrastructure/auth/auth_service.dart` — Strip to pure JWT (remove ~600 lines)
- `lib/infrastructure/auth/account_service.dart` — Add `recoverFromCrossDeviceKey`, `recreateCrossDeviceKey`, `listDevices`, `revokeDevice`, `importUltimateKeyForSession`, `clearUltimateKeySession`
- `lib/infrastructure/crypto/crypto_key_repository.dart` — Add temporary ultimate key session methods
- `lib/features/settings/cubits/device_management/device_management_cubit.dart` — Switch from AuthService to AccountService for listDevices/revokeDevice
- `lib/features/settings/pages/settings_page.dart` — Switch delete account to DeleteService
- `lib/dev/widgets/dev_tools_sheet.dart` — Switch factory reset to DeleteService
- `lib/app/bootstrap.config.dart` — Update DI wiring

### Files That Stay Unchanged
- `lib/features/onboarding/cubits/onboarding_cubit.dart` — already uses AccountService
- `lib/features/settings/cubits/recovery_key/recovery_key_cubit.dart` — already uses AccountService
- `lib/features/device_pairing/` — uses IPairingService, not affected
- `lib/infrastructure/auth/auth_repository.dart` — no changes needed

---

### Task 1: Add Temporary Ultimate Key Session to CryptoKeyRepository

**Context:** Operations like revoking devices from a new device need the ultimate key temporarily. Currently the ultimate key is either generated (during createAccount) or imported (during recovery) but never held for follow-up operations. We need an explicit "temporary session" where the key is imported, used for one or more operations, then explicitly cleared.

**Files:**
- Modify: `lib/infrastructure/crypto/crypto_key_repository.dart`
- Test: `test/infrastructure/crypto/crypto_key_repository_test.dart` (if exists, otherwise create)

- [ ] **Step 1: Read CryptoKeyRepository and understand the existing `_ultimateKey` field and `importUltimateKeyJwk` method**

- [ ] **Step 2: Add temporary ultimate key session methods to ICryptoKeyRepository interface**

Add to the abstract interface:
```dart
/// Import ultimate key JWK and hold in memory for follow-up operations.
/// Does NOT persist. Call [clearTemporaryUltimateKey] when done.
Future<KeyDuo> importUltimateKeyTemporary(String jwk);

/// Returns the temporary ultimate key if loaded, null otherwise.
KeyDuo? get temporaryUltimateKey;

/// Wipes the temporary ultimate key from memory.
void clearTemporaryUltimateKey();
```

- [ ] **Step 3: Implement in CryptoKeyRepository**

```dart
KeyDuo? _temporaryUltimateKey;

@override
Future<KeyDuo> importUltimateKeyTemporary(String jwk) async {
  final keyDuo = await importUltimateKeyJwk(jwk);
  _temporaryUltimateKey = keyDuo;
  return keyDuo;
}

@override
KeyDuo? get temporaryUltimateKey => _temporaryUltimateKey;

@override
void clearTemporaryUltimateKey() {
  _temporaryUltimateKey = null;
}
```

- [ ] **Step 4: Run dart analyze**

Run: `dart analyze lib/infrastructure/crypto/`

- [ ] **Step 5: Commit**

```
feat: add temporary ultimate key session to CryptoKeyRepository
```

---

### Task 2: Move recoverFromCrossDeviceKey and recreateCrossDeviceKey to AccountService

**Context:** These methods are currently in AuthService but are account lifecycle operations. AccountService already has recoverAccount — these are sibling flows. `recoverFromCrossDeviceKey` needs `_storeAuthSession` which stores JWT via `_client.auth.updateSignedInUser`. Since AccountService already has `_client`, we add a local `_storeAuthSession` helper.

**Files:**
- Modify: `lib/infrastructure/auth/account_service.dart` — add both methods + `_storeAuthSession` helper
- Modify: `lib/infrastructure/auth/auth_service.dart` — remove both methods (but NOT yet — do that in Task 4)

- [ ] **Step 1: Read both files to understand the current implementations**

- [ ] **Step 2: Add `_storeAuthSession` helper to AccountService**

Copy from AuthService (lines 938-962). It only depends on `_client`:
```dart
Future<void> _storeAuthSession(AuthenticationResult result) async {
  final details = result.details;
  if (details == null) return;
  final token = details['token'];
  final authUserIdStr = details['authUserId'];
  final authStrategy = details['authStrategy'] ?? 'jwt';
  if (token == null || authUserIdStr == null) return;
  final tokenExpiresAtStr = details['tokenExpiresAt'];
  final refreshToken = details['refreshToken'];
  final authSuccess = AuthSuccess(
    authStrategy: authStrategy,
    token: token,
    tokenExpiresAt: tokenExpiresAtStr != null ? DateTime.tryParse(tokenExpiresAtStr) : null,
    refreshToken: refreshToken,
    authUserId: UuidValue.fromString(authUserIdStr),
    scopeNames: {},
  );
  await _client.auth.updateSignedInUser(authSuccess);
}
```

Add required imports to AccountService:
```dart
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show AuthSuccess, FlutterAuthSessionManagerExtension;
import 'package:serverpod_client/serverpod_client.dart' show UuidValue;
import 'package:anonaccount_client/anonaccount_client.dart'
    show AuthenticationResult; // add to existing import
```

- [ ] **Step 3: Add `recoverFromCrossDeviceKey` to AccountService**

Copy the method body from AuthService. Adapt:
- Replace `_prefs.setBool(_registeredWithServerKey, true)` → `_authRepo.setRegistered()`
- Replace `_secureStorage.storeSecureData(_registeredWithServerKey, 'true')` → `_authRepo.setRegistered()`
- Keep `_storeAuthSession(authResult)` — now calls the local helper

- [ ] **Step 4: Add `recreateCrossDeviceKey` to AccountService**

Copy the method body from AuthService. No auth-specific dependencies — it uses `_keyRepository`, `_encryption`, `_client`.

- [ ] **Step 5: Add `importUltimateKeyForSession` and `clearUltimateKeySession` to AccountService**

```dart
/// Import ultimate key and hold for follow-up operations (e.g., revoke devices).
/// Call [clearUltimateKeySession] when navigating away.
Future<void> importUltimateKeyForSession(String jwk) {
  return tryMethod(
    () async {
      await _keyRepository.importUltimateKeyTemporary(jwk);
    },
    (message, [cause]) => AccountRecoveryException(message, cause: cause),
    'importUltimateKeyForSession',
  );
}

/// Clear the temporary ultimate key from memory.
void clearUltimateKeySession() {
  _keyRepository.clearTemporaryUltimateKey();
}
```

- [ ] **Step 6: Add `listDevices` and `revokeDevice` to AccountService**

Copy from AuthService. These use `_keyRepository`, `_encryption`, `_client` — all available in AccountService. Wrap with tryMethod. Use `_wrapAuthError` or create an `AccountException` wrapper.

NOTE: `_wrapAuthError` is defined in auth_service.dart as a top-level function. Either copy it to account_service.dart or import it. Simplest: define a local `_wrapAccountError` that creates `AuthException` (imported from auth_service.dart).

- [ ] **Step 7: Run dart analyze on account_service.dart**

- [ ] **Step 8: Commit**

```
feat: add device management and cross-device recovery to AccountService
```

---

### Task 3: Create DeleteService

**Context:** Destructive operations should be isolated. DeleteService handles:
1. `deleteAccount()` — server-side delete + delete iCloud cross-device key
2. `factoryReset()` — local wipe (keys, DB, PowerSync, entitlements, registration flag, guided tours) + delete iCloud cross-device key

Currently delete is inline in settings_page.dart (6 service calls) and factory reset is inline in dev_tools_sheet.dart (7 service calls). Both should be single service calls.

**Files:**
- Create: `lib/infrastructure/auth/delete_service.dart`

- [ ] **Step 1: Create DeleteService**

```dart
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../data/repositories/e2ee_puller.dart';
import '../../data/sync/powersync_service.dart';
import '../../features/app_syncing_mode/cubits/app_syncing_cubit.dart';
import '../../features/guided_tour/guided_tour_service.dart';
import '../core/try_operation.dart';
import '../crypto/crypto_key_repository.dart';
import '../purchase/entitlement_repository.dart';
import 'account_service.dart';
import 'auth_repository.dart';
import 'auth_service.dart' show AuthException;

/// Exception for delete/reset operations.
class DeleteException implements Exception {
  const DeleteException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'DeleteException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Handles destructive operations — server-side account deletion and local factory reset.
@lazySingleton
class DeleteService {
  final AccountService _accountService;
  final AuthRepository _authRepo;
  final ICryptoKeyRepository _keyRepository;
  final EntitlementRepository _entitlementRepo;
  final IPowerSyncRepository _powerSync;
  final IE2EEPuller _puller;
  final GuidedTourService _guidedTourService;

  DeleteService(
    this._accountService,
    this._authRepo,
    this._keyRepository,
    this._entitlementRepo,
    this._powerSync,
    this._puller,
    this._guidedTourService,
  );

  /// Delete account on server + clean up iCloud cross-device key.
  ///
  /// Does NOT wipe local data — call [factoryReset] after if needed.
  Future<void> deleteAccount() {
    return tryMethod(
      () async {
        // 1. Delete account on server
        await _accountService.deleteAccount();

        // 2. Delete iCloud cross-device key
        if (_keyRepository.isCrossDeviceStorageAvailable) {
          try {
            await _keyRepository.deleteCrossDeviceKey();
          } catch (e) {
            debugPrint('DeleteService: Cross-device key deletion failed (non-critical): $e');
          }
        }

        // 3. Clear registration flag
        await _authRepo.clearRegistrationFlag();

        // 4. Clear entitlements
        await _entitlementRepo.clear();
      },
      DeleteException.new,
      'deleteAccount',
    );
  }

  /// Factory reset — wipe all local state + iCloud cross-device key.
  ///
  /// Does NOT delete the server-side account.
  Future<void> factoryReset() {
    return tryMethod(
      () async {
        // 1. Disconnect sync
        if (_powerSync.isConnected) {
          await _powerSync.disconnect();
        }

        // 2. Dispose E2EE puller
        if (_puller.isListening) {
          await _puller.dispose();
          await _puller.resetCheckpoints();
        }

        // 3. Clear guided tours
        await _guidedTourService.resetAllTours();

        // 4. Clear entitlements
        await _entitlementRepo.clear();

        // 5. Clear all crypto keys (including iCloud cross-device key)
        await _keyRepository.clearKeys();

        // 6. Clear registration flag
        await _authRepo.clearRegistrationFlag();
      },
      DeleteException.new,
      'factoryReset',
    );
  }
}
```

- [ ] **Step 2: Run dart analyze**

- [ ] **Step 3: Commit**

```
feat: create DeleteService for account deletion and factory reset
```

---

### Task 4: Strip AuthService to Pure JWT

**Context:** AuthService currently has ~1067 lines. After this task it should have ~200 lines — only JWT session management. All account lifecycle, device management, recovery, and delete methods are removed.

**Files:**
- Modify: `lib/infrastructure/auth/auth_service.dart`

- [ ] **Step 1: Read AuthService fully**

- [ ] **Step 2: Remove these methods from AuthService**

Remove (they now exist in AccountService):
- `createAccount()` and all its inline code (~150 lines)
- `registerAccountWithServer()` (~120 lines)
- `ensureRegistered()` (~5 lines)
- `recoverAccount()` (~120 lines)
- `recoverFromCrossDeviceKey()` (~130 lines)
- `recreateCrossDeviceKey()` (~50 lines)
- `deleteAccount()` (~25 lines)
- `validateRecoveryKey()` (~10 lines)
- `listDevices()` (~25 lines)
- `revokeDevice()` (~25 lines)
- `signOut()` (~8 lines) — now in DeleteService as factoryReset
- `getCurrentDevicePublicKeyHex()` (~8 lines) — callers use ICryptoKeyRepository directly
- `_storeRegistrationPayload()` / `_getRegistrationPayload()` (~10 lines)
- `clearRegistrationFlag()` — now in AuthRepository

Remove constants:
- `_registrationPayloadKey`
- `_crossDeviceRegistrationBlobKey`
- `_registeredWithServerKey`

- [ ] **Step 3: Replace raw _prefs usage with AuthRepository**

Change constructor: remove `SecurePreferences _prefs`, add `AuthRepository _authRepo`.

In `ensureAuthenticated()`:
- Replace the retry logic. Remove the `ensureRegistered` call — AuthService should NOT know about registration. Instead, just throw on DEVICE_NOT_FOUND. The caller handles it.
- Simplified `ensureAuthenticated`:
```dart
Future<void> ensureAuthenticated() async {
  if (_client.auth.isAuthenticated) return;
  await authenticateDevice();
}
```

Wait — we need the DEVICE_NOT_FOUND retry somewhere. Since `SyncService.connect()` calls `ensureAuthenticated`, it should catch the auth failure and handle re-registration via AccountService. Move the retry logic to wherever the caller is.

Actually, to avoid breaking all callers at once, keep a simple retry in ensureAuthenticated but delegate to AccountService:

```dart
Future<void> ensureAuthenticated({String deviceLabel = 'auto'}) async {
  if (_client.auth.isAuthenticated) return;
  await authenticateDevice();
}
```

No — the user explicitly said: "ensureAuthenticated — lazy JWT, throws on DEVICE_NOT_FOUND (no retry)". So we simplify it and let callers handle the retry.

- [ ] **Step 4: Remove `ISecureStorage _secureStorage` from AuthService if no longer needed**

Check if `_storeAuthSession` uses it. It doesn't — it uses `_client.auth.updateSignedInUser`. So remove `_secureStorage` from constructor.

- [ ] **Step 5: Remove `SecurePreferences _prefs` from AuthService**

Not needed anymore — `isRegisteredWithServer` and `clearRegistrationFlag` are in AuthRepository. But check if `_prefs` is used for anything else. If not, remove it.

- [ ] **Step 6: Clean up imports**

Remove all unused imports after stripping methods.

- [ ] **Step 7: The resulting AuthService should look like**

```dart
@lazySingleton
class AuthService {
  final ICryptoKeyRepository _keyRepository;
  final IDataEncryption _encryption;
  final Client _client;

  bool _isInitialized = false;

  AuthService(this._keyRepository, this._encryption, this._client);

  Future<void> initialize() { ... }              // ~10 lines
  Future<bool> isAuthenticated() { ... }          // ~10 lines
  Future<AuthenticationResult> authenticateDevice() { ... }  // ~50 lines
  Future<void> ensureAuthenticated() { ... }      // ~5 lines (no retry)
  Future<void> _storeAuthSession() { ... }        // ~25 lines
}
```

Total: ~100-150 lines.

- [ ] **Step 8: Run dart analyze**

- [ ] **Step 9: Commit**

```
refactor: strip AuthService to pure JWT session management
```

---

### Task 5: Wire Callers to Correct Services

**Context:** Several callers still use AuthService for operations that now live in AccountService or DeleteService. Update them.

**Files:**
- Modify: `lib/features/settings/cubits/device_management/device_management_cubit.dart`
- Modify: `lib/features/settings/pages/settings_page.dart`
- Modify: `lib/features/settings/widgets/device_list_section.dart`
- Modify: `lib/dev/widgets/dev_tools_sheet.dart`
- Modify: `lib/infrastructure/sync/sync_service.dart`
- Modify: `lib/infrastructure/purchase/entitlement_service.dart`
- Modify: `lib/infrastructure/purchase/providers/in_app_purchase_repository.dart`

- [ ] **Step 1: DeviceManagementCubit — switch listDevices/revokeDevice to AccountService**

Currently depends on both `AuthService` and `AccountService`.
- `_authService.getCurrentDevicePublicKeyHex()` → `_keyRepository.getDeviceSigningPublicKeyHex()` (use ICryptoKeyRepository directly)
- `_authService.listDevices()` → `_accountService.listDevices()`
- `_authService.revokeDevice(deviceId)` → `_accountService.revokeDevice(deviceId)`
- Remove `AuthService` dependency, add `ICryptoKeyRepository` if not already there

- [ ] **Step 2: settings_page.dart — switch delete account to DeleteService**

The `_DeleteAccountButton` currently does 6 inline service calls. Replace with:
```dart
await GetIt.instance<DeleteService>().deleteAccount();
// Then navigate away / switch to local mode
await GetIt.instance<AppSyncingCubit>().switchToLocal();
```

Note: `switchToLocal` disconnects PowerSync internally via SyncService, so DeleteService doesn't need to do that. But DeleteService.deleteAccount already handles: server delete + cross-device key + registration flag + entitlements. Check if switchToLocal is still needed or if DeleteService covers it.

- [ ] **Step 3: dev_tools_sheet.dart — switch factory reset to DeleteService**

The `_DevFactoryResetButton` currently does 7 inline service calls. Replace with:
```dart
await GetIt.instance<DeleteService>().factoryReset();
AppRouter.resetKeyCheck();
```

Check if `DevSeederService.clearAll()` (DB table wipe) should be part of DeleteService.factoryReset or remain separate. It's DB-level cleanup that factory reset probably needs.

- [ ] **Step 4: device_list_section.dart — switch isRegisteredWithServer**

Currently: `GetIt.instance<AuthService>().isRegisteredWithServer`
Change to: `GetIt.instance<AuthRepository>().isRegisteredWithServer`

- [ ] **Step 5: SyncService — handle ensureAuthenticated failure**

Currently calls `_authService.ensureAuthenticated()`. Since ensureAuthenticated no longer retries on DEVICE_NOT_FOUND, SyncService needs to handle it:

```dart
try {
  await _authService.ensureAuthenticated();
} on DeviceAuthenticationException catch (e) {
  // Device not found on server — re-register and retry
  await _accountService.ensureRegistered(deviceLabel: 'auto');
  await _authService.ensureAuthenticated();
}
```

Add `AccountService` as a dependency of SyncService.

- [ ] **Step 6: EntitlementService — check if it still needs AuthService**

Currently depends on `AuthService` for `ensureAuthenticated()`. This is fine — that stays in AuthService.

- [ ] **Step 7: InAppPurchaseRepository — check if it still needs AuthService**

Currently depends on `AuthService`. Check what methods it calls. If only `ensureAuthenticated`, no change needed.

- [ ] **Step 8: Run dart analyze**

- [ ] **Step 9: Commit**

```
refactor: wire callers to AccountService and DeleteService
```

---

### Task 6: Update DI Wiring (bootstrap.config.dart)

**Context:** Since we changed constructor signatures for AuthService, AccountService, DeviceManagementCubit, SyncService, and added DeleteService, the DI registrations need updating. This file is auto-generated by build_runner but we can't run it, so update manually.

**Files:**
- Modify: `lib/app/bootstrap.config.dart`

- [ ] **Step 1: Read bootstrap.config.dart and find all registrations that need updating**

- [ ] **Step 2: Update AuthService registration**

Remove `SecurePreferences` and `ISecureStorage` params (if removed from constructor). The constructor should now only take `ICryptoKeyRepository`, `IDataEncryption`, `Client`.

- [ ] **Step 3: Add DeleteService registration**

```dart
gh.lazySingleton<DeleteService>(
  () => DeleteService(
    gh<AccountService>(),
    gh<AuthRepository>(),
    gh<ICryptoKeyRepository>(),
    gh<EntitlementRepository>(),
    gh<IPowerSyncRepository>(),
    gh<IE2EEPuller>(),
    gh<GuidedTourService>(),
  ),
);
```

- [ ] **Step 4: Update DeviceManagementCubit registration**

Remove `AuthService` param, add `ICryptoKeyRepository` if needed.

- [ ] **Step 5: Update SyncService registration**

Add `AccountService` param.

- [ ] **Step 6: Run dart analyze**

- [ ] **Step 7: Commit**

```
chore: update DI wiring for auth/account/delete service split
```

---

### Task 7: Remove Dead Code from AuthService

**Context:** After all callers are updated, verify AuthService has no remaining dead methods, unused imports, or orphaned constants. Also remove AccountCreationResult, AccountCreationException, AccountRecoveryException if they're only used by AccountService (but they're likely imported by AccountService from auth_service.dart, so keep them where they are).

**Files:**
- Modify: `lib/infrastructure/auth/auth_service.dart` — final cleanup

- [ ] **Step 1: Verify no callers reference removed methods**

Search for all AuthService method names that were removed. If any caller still references them, fix the caller.

- [ ] **Step 2: Remove any unused imports from auth_service.dart**

- [ ] **Step 3: Run full test suite**

```bash
cd quanitya_flutter && flutter test --no-pub 2>&1 > /tmp/flutter_test_results.txt
```

Check results. Fix any test failures caused by the refactor.

- [ ] **Step 4: Run dart analyze**

Ensure 0 errors, 0 warnings.

- [ ] **Step 5: Commit**

```
chore: remove dead code from AuthService after split
```

---

### Task 8: Final Verification

- [ ] **Step 1: Verify AuthService is pure JWT (~100-150 lines)**

Methods: `initialize`, `isAuthenticated`, `authenticateDevice`, `ensureAuthenticated`, `_storeAuthSession`

- [ ] **Step 2: Verify AccountService has all account + device methods**

Methods: `createAccount`, `registerAccountWithServer`, `ensureRegistered`, `recoverAccount`, `recoverFromCrossDeviceKey`, `recreateCrossDeviceKey`, `validateRecoveryKey`, `importUltimateKeyForSession`, `clearUltimateKeySession`, `listDevices`, `revokeDevice`

- [ ] **Step 3: Verify DeleteService has both destructive methods**

Methods: `deleteAccount`, `factoryReset`

- [ ] **Step 4: Verify all operations from the requirements table are covered**

| Operation | Service | Method |
|-----------|---------|--------|
| Create Account | AccountService | `createAccount()` |
| Sign In | AuthService | `authenticateDevice()` / `ensureAuthenticated()` |
| Register Device | AccountService | `registerAccountWithServer()` / `ensureRegistered()` |
| QR Device Pairing | IPairingService | (unchanged) |
| Monitor Registration | IPairingService | (unchanged) |
| Retrieve Encrypted Data Key | AccountService | `recoverFromCrossDeviceKey()` |
| Recover via Ultimate Key | AccountService | `recoverAccount()` |
| Revoke Device | AccountService | `revokeDevice()` |
| List Devices | AccountService | `listDevices()` |
| Cross-Device Key Recreation | AccountService | `recreateCrossDeviceKey()` |
| Delete Account | DeleteService | `deleteAccount()` |
| Factory Reset | DeleteService | `factoryReset()` |
| Validate Recovery Key | AccountService | `validateRecoveryKey()` |
| Recovery Key Backup | KeyExportService | (unchanged, 4 methods) |
| Import Ultimate Key Session | AccountService | `importUltimateKeyForSession()` / `clearUltimateKeySession()` |

- [ ] **Step 5: Full test suite passes**

- [ ] **Step 6: Final commit**

```
refactor: complete auth/account/delete service split
```
