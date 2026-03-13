# Plan: iCloud Device Key for Cross-Device Identity

## Problem

Apple App Store reviewers may test "buy on device A, restore on device B." With our current setup, each device has a unique local-only device key = unique identity = unique account. Restore purchases on device B shows no entitlements because it's a different account.

## Solution

Auto-generate a second device key during onboarding that syncs via iCloud Keychain. New Apple devices find this key and use it to authenticate as the same account, then register their own local device key.

## Key Hierarchy

- **Ultimate Key** — recovery master key, user-backed-up (file, clipboard, iCloud Keychain, biometrics). Never stored on device permanently. Unchanged.
- **Device Key** (`device_key`) — local Keychain only, per-device identity. Used for daily auth. Unchanged.
- **iCloud Device Key** (`device_key_icloud`) — **NEW**. iCloud Keychain with `synchronizable: true`. A regular device key that roams across Apple devices. Revocable. iOS only.
- **Symmetric Data Key** — AES-256-GCM for E2EE data. Stored locally, also encrypted per-device as `encryptedDataKey` on server. Unchanged.

## Existing Infrastructure Used

- `PlatformSecureStorage` — already has `storeWithPlatformOptions(synchronizable: true)` for iCloud Keychain read/write
- `CryptoKeyRepository` — generates KeyDuo (ECDSA P-256 signing + ECDH P-256 encryption)
- `KeyDuoSerializer` — import/export KeyDuo as JWK
- `DeviceEndpoint.registerDevice()` — registers a device key under an account (called during account creation, same flow, same moment)
- `DeviceEndpoint.registerDeviceForAccount()` — registers a new device under the caller's authenticated account
- `DeviceEndpoint.getDeviceBySigningKey()` — unauthenticated lookup, returns `encryptedDataKey` blob (no account identifiers exposed)
- `DeviceEndpoint.authenticateDevice()` — challenge-response auth. The auth handler uses the device signing key hex from the `Authorization` header. If the iCloud key is registered as a device on the server, device B just puts the iCloud key's hex in the header and the server authenticates it like any other device.
- `AuthService.createAccount()` — account creation flow
- `DeviceManagementCubit` — UI for listing/revoking devices

## Decisions

- **Automatic creation**: iCloud device key is generated automatically during account creation on iOS. No opt-in needed. User can revoke later from Settings > Devices.
- **Fixed key name**: `device_key_icloud`. One account per Apple ID. Multiple accounts on same Apple ID is not a supported scenario (edge case we don't care about).
- **Label**: "iCloud" — simple, shown in device list with a cloud icon.
- **Android**: Skipped entirely. No iCloud on Android. Google equivalent is a separate future effort.
- **iCloud sync delay**: Accepted limitation. If a user sets up a second device before iCloud syncs, they get a new account. This is a tiny window and not worth engineering around.

## Flow A: Account Creation (new user, no keys anywhere)

1. `generateAccountKeys()` creates ultimate key, device key, symmetric key (existing)
2. Register local device key with server via `registerDevice(accountId, deviceKeyHex, encryptedDataKey, deviceLabel)` (existing)
3. **NEW**: Generate a second KeyDuo for iCloud
4. **NEW**: Encrypt the symmetric data key with the iCloud KeyDuo's encryption public key → `icloudEncryptedDataKey`
5. **NEW**: Register iCloud device key with server via `registerDevice(accountId, icloudKeyHex, icloudEncryptedDataKey, "iCloud")`
6. **NEW**: Store iCloud KeyDuo JWK in iCloud Keychain as `device_key_icloud` with `synchronizable: true`
7. User proceeds to recovery key backup page (unchanged)

Steps 3-6 only run on iOS. On Android, skip straight to step 7.

## Flow B: New Device (iCloud key exists, no local key)

App launch → `CryptoKeyRepository.getKeyStatus()` returns `notInitialized` (no local `device_key`).

1. **NEW**: Check iCloud Keychain for `device_key_icloud`
2. If not found → normal onboarding (Flow A)
3. If found → import the iCloud KeyDuo from JWK
4. Auth with server using iCloud key — the auth handler recognizes the iCloud key's hex in the `Authorization` header since it's a registered device. Call `generateAuthChallenge()` → sign with iCloud key → `authenticateDevice(challenge, signature)` → server confirms session, returns `accountId`
5. Call `getDeviceBySigningKey(icloudKeyHex)` → get `encryptedDataKey` → decrypt with iCloud key's ECDH private key → recover symmetric data key
6. Generate new local device key
7. Encrypt symmetric data key with new local device key's encryption public key → `localEncryptedDataKey`
8. Register new local device key: `registerDeviceForAccount(localKeyHex, localEncryptedDataKey, deviceLabel)` — this uses the authenticated iCloud session to derive the accountId
9. Store local device key and symmetric data key in local Keychain
10. Show brief "Recovering your account..." screen during this process
11. Skip onboarding → go to home

If any step fails (network error, server rejection), wipe partial state and fall back to normal onboarding.

## Flow C: Revoke iCloud Key

User goes to Settings > Devices > sees "iCloud" device > taps Revoke.

1. `DeviceManagementCubit.revokeDevice(icloudDeviceId)` (existing server call)
2. **NEW**: Delete `device_key_icloud` from iCloud Keychain via `deleteWithPlatformOptions(key: 'device_key_icloud', synchronizable: true)`
3. iCloud key is now revoked on server and deleted from Keychain

If device B still has the iCloud key cached and tries to auth, server rejects (device is revoked) → device B falls back to onboarding.

## Flow D: Re-create iCloud Key

User wants to re-enable cross-device sync after revoking. Available from Settings > Devices.

1. **NEW**: Generate new iCloud KeyDuo
2. Encrypt symmetric data key with new iCloud key's encryption public key
3. Register with server via `registerDeviceForAccount(newIcloudKeyHex, newIcloudEncryptedDataKey, "iCloud")`
4. Store in iCloud Keychain as `device_key_icloud` with `synchronizable: true`

## Files to Modify

### `lib/infrastructure/crypto/interfaces/i_secure_storage.dart`
- Add `storeICloudDeviceKey(String jwk)`, `getICloudDeviceKey()`, `deleteICloudDeviceKey()` — convenience methods wrapping `storeWithPlatformOptions` with fixed key name `device_key_icloud`

### `lib/infrastructure/platform/platform_secure_storage.dart`
- Implement the new iCloud device key convenience methods

### `lib/infrastructure/crypto/crypto_key_repository.dart`
- Add `CryptoKeyStatus.iCloudRecoveryAvailable` enum value
- Modify `getKeyStatus()` — if no local `device_key` but iCloud key exists, return `iCloudRecoveryAvailable`
- Add `generateICloudDeviceKey()` — generates KeyDuo, stores in iCloud Keychain, returns KeyDuo
- Add `getICloudDeviceKey()` — reads from iCloud Keychain, returns KeyDuo or null
- Add `deleteICloudDeviceKey()` — removes from iCloud Keychain
- Modify `clearKeys()` — also delete `device_key_icloud` from iCloud Keychain

### `lib/infrastructure/auth/auth_service.dart`
- Modify `createAccount()` — after registering local device, also generate and register iCloud device key (iOS only)
- Add `recoverFromICloudKey()` — implements Flow B (auth with iCloud key, recover symmetric key, register new local device)

### `lib/app/bootstrap.dart` or app router guard
- On launch, if `getKeyStatus()` returns `iCloudRecoveryAvailable`, trigger `recoverFromICloudKey()` instead of onboarding

### `lib/features/settings/cubits/device_management/device_management_cubit.dart`
- Modify `revokeDevice()` — if revoking the iCloud device AND platform is iOS, also delete from iCloud Keychain
- Add `recreateICloudKey()` — implements Flow D

### `lib/features/settings/widgets/device_list_section.dart`
- Show iCloud device with cloud icon (detect by label "iCloud")
- Add "Enable iCloud Sync" button if no iCloud device exists in the device list (iOS only)

## Server Changes Needed

None. All existing endpoints support this flow.

## Edge Cases

1. **User has iCloud disabled** — `storeWithPlatformOptions(synchronizable: true)` still works locally, just doesn't sync. Not harmful, just doesn't help cross-device.
2. **User deletes app from all devices** — iCloud Keychain entry persists. Reinstall on any Apple device recovers via Flow B.
3. **Android** — Skipped. No iCloud Keychain. Future work.
4. **Revoke iCloud key, device B still has it cached** — Device B tries to auth → server rejects (revoked) → device B falls back to onboarding.
5. **Two new devices find iCloud key simultaneously** — Both call `registerDeviceForAccount` with unique local keys. Server handles fine. Both succeed.
6. **iCloud sync delay** — Accepted. Tiny window. New device gets normal onboarding if key hasn't synced yet.
