# Plan: Block Store Device Key for Cross-Device Identity (Android)

## Problem

Google Play requires that subscription restore works across devices. With our current setup, each Android device generates a unique local device key = unique identity = unique account. Restore purchases on device B shows no entitlements because it's a different account.

This is the Android equivalent of `plan_icloud_device_key.md` (iOS). Same problem, different storage backend.

## Solution

Auto-generate a second device key during onboarding that persists via Google Block Store API. New Android devices retrieve this key during device setup/restore and use it to authenticate as the same account, then register their own local device key.

## Block Store API Overview

Google Block Store is a credential storage API powered by Google Play Services. Key properties:

- **Storage**: Key-value pairs, max 4KB per entry, up to 16 entries per app
- **Encryption**: End-to-end encrypted on Android 9+ (API 29+) with screen lock (PIN/pattern/password)
- **Persistence**: Survives app uninstall/reinstall if user has Backup services enabled
- **Cross-device**: Transfers during device-to-device restore or cloud restore (not real-time sync like iCloud Keychain)
- **Cloud backup**: Controlled via `shouldBackupToCloud` flag — must be `true` for cross-device transfer
- **Requires**: Google Play Services, Android 6+ (API 23+) to store, Android 9+ (API 29+) to restore

### Key Differences from iCloud Keychain

| | iCloud Keychain | Block Store |
|---|---|---|
| Sync timing | Real-time, continuous | Only during device setup/restore |
| Availability | Always on Apple devices | Requires Backup enabled |
| Encryption | Always E2EE | E2EE only with screen lock on Android 9+ |
| Survives uninstall | Always (Keychain) | Only if Backup enabled |
| User dependency | Minimal | Must have Google account + Backup |

The Block Store is less reliable than iCloud Keychain — it depends on user having Backup enabled and only transfers during device setup, not on-demand. But it covers the critical "new device restore" scenario that Google Play review cares about.

## Flutter Plugin

Use `play_services_block_store` (pub.dev, updated June 2025). API:

```dart
final blockStore = PlayServicesBlockStore();

// Store
await blockStore.save(key: 'device_key_blockstore', value: jwkString);

// Retrieve
final jwk = await blockStore.retrieve(key: 'device_key_blockstore'); // String? — null if not found

// Delete
await blockStore.delete(key: 'device_key_blockstore');
```

## Key Hierarchy

Same as iOS plan, with the Android equivalent:

- **Ultimate Key** — recovery master key, user-backed-up. Unchanged.
- **Device Key** (`device_key`) — local only, per-device identity. Used for daily auth. Unchanged.
- **Block Store Device Key** (`device_key_blockstore`) — **NEW**. Stored in Google Block Store with `shouldBackupToCloud: true`. A regular device key that transfers across Android devices. Revocable. Android only.
- **Symmetric Data Key** — AES-256-GCM for E2EE data. Unchanged.

## Existing Infrastructure Used

Same server-side infrastructure as iOS plan — zero server changes:

- `PlatformSecureStorage` — local key storage (unchanged)
- `CryptoKeyRepository` — generates KeyDuo (ECDSA P-256 signing + ECDH P-256 encryption)
- `KeyDuoSerializer` — import/export KeyDuo as JWK
- `DeviceEndpoint.registerDevice()` — registers a device key under an account
- `DeviceEndpoint.registerDeviceForAccount()` — registers a new device under the caller's authenticated account
- `DeviceEndpoint.getDeviceBySigningKey()` — unauthenticated lookup, returns `encryptedDataKey` blob
- `DeviceEndpoint.authenticateDevice()` — challenge-response auth
- `DeviceManagementCubit` — UI for listing/revoking devices

## Decisions

- **Automatic creation**: Block Store device key is generated automatically during account creation on Android. No opt-in needed. User can revoke later from Settings > Devices.
- **Fixed key name**: `device_key_blockstore`. One account per Google account.
- **Cloud backup**: `shouldBackupToCloud: true` — required for cross-device transfer. Without this, Block Store only persists locally across uninstall/reinstall, which doesn't solve the cross-device problem.
- **Label**: "Google Backup" — shown in device list. Distinct from "iCloud" label on iOS.
- **iOS**: Skipped entirely. iOS uses iCloud Keychain (see `plan_icloud_device_key.md`).
- **Graceful degradation**: If Block Store is unavailable (no Google Play Services, Backup disabled, pre-Android 6), skip silently. User still has local device key + recovery phrase.
- **Transfer timing**: Unlike iCloud Keychain (real-time sync), Block Store only transfers during device setup. Accepted limitation — covers the Google Play review scenario.

## Flow A: Account Creation (new user, no keys anywhere)

1. `generateAccountKeys()` creates ultimate key, device key, symmetric key (existing)
2. Register local device key with server via `registerDevice(accountId, deviceKeyHex, encryptedDataKey, deviceLabel)` (existing)
3. **NEW**: Generate a second KeyDuo for Block Store
4. **NEW**: Encrypt the symmetric data key with the Block Store KeyDuo's encryption public key → `blockstoreEncryptedDataKey`
5. **NEW**: Register Block Store device key with server via `registerDevice(accountId, blockstoreKeyHex, blockstoreEncryptedDataKey, "Google Backup")`
6. **NEW**: Store Block Store KeyDuo JWK via `blockStore.save(key: 'device_key_blockstore', value: jwkString)`
7. User proceeds to recovery key backup page (unchanged)

Steps 3-6 only run on Android. On iOS, skip straight to step 7.

**Error handling**: If Block Store save fails (Play Services unavailable, etc.), log warning and continue. The local device key and recovery phrase still work. Block Store is best-effort.

## Flow B: New Device (Block Store key exists, no local key)

App launch → `CryptoKeyRepository.getKeyStatus()` returns `notInitialized` (no local `device_key`).

1. **NEW**: Check Block Store for `device_key_blockstore` via `blockStore.retrieve(key: 'device_key_blockstore')`
2. If not found or null → normal onboarding (Flow A)
3. If found → import the Block Store KeyDuo from JWK
4. Auth with server using Block Store key — call `generateAuthChallenge()` → sign with Block Store key → `authenticateDevice(challenge, signature)` → server confirms session, returns `accountId`
5. Call `getDeviceBySigningKey(blockstoreKeyHex)` → get `encryptedDataKey` → decrypt with Block Store key's ECDH private key → recover symmetric data key
6. Generate new local device key
7. Encrypt symmetric data key with new local device key's encryption public key → `localEncryptedDataKey`
8. Register new local device key: `registerDeviceForAccount(localKeyHex, localEncryptedDataKey, deviceLabel)` — uses the authenticated Block Store session to derive accountId
9. Store local device key and symmetric data key in local storage
10. Show brief "Recovering your account..." screen during this process
11. Skip onboarding → go to home

If any step fails (network error, server rejection, Block Store key revoked), wipe partial state and fall back to normal onboarding.

## Flow C: Revoke Block Store Key

User goes to Settings > Devices > sees "Google Backup" device > taps Revoke.

1. `DeviceManagementCubit.revokeDevice(blockstoreDeviceId)` (existing server call)
2. **NEW**: Delete `device_key_blockstore` from Block Store via `blockStore.delete(key: 'device_key_blockstore')`
3. Block Store key is now revoked on server and deleted from Block Store

If device B already restored the Block Store key and tries to auth, server rejects (device is revoked) → device B falls back to onboarding.

## Flow D: Re-create Block Store Key

User wants to re-enable cross-device sync after revoking. Available from Settings > Devices.

1. **NEW**: Generate new Block Store KeyDuo
2. Encrypt symmetric data key with new Block Store key's encryption public key
3. Register with server via `registerDeviceForAccount(newBlockstoreKeyHex, newBlockstoreEncryptedDataKey, "Google Backup")`
4. Store in Block Store via `blockStore.save(key: 'device_key_blockstore', value: jwkString)`

## Files to Modify

### `pubspec.yaml`
- Add dependency: `play_services_block_store: ^latest`

### `lib/infrastructure/crypto/interfaces/i_secure_storage.dart`
- Add `storeBlockStoreDeviceKey(String jwk)`, `getBlockStoreDeviceKey()`, `deleteBlockStoreDeviceKey()` — convenience methods wrapping `play_services_block_store` with fixed key name `device_key_blockstore`

### `lib/infrastructure/platform/platform_secure_storage.dart`
- Implement the new Block Store device key convenience methods
- Wrap all Block Store calls in try/catch — graceful degradation if Play Services unavailable

### `lib/infrastructure/crypto/crypto_key_repository.dart`
- Add `CryptoKeyStatus.blockStoreRecoveryAvailable` enum value
- Modify `getKeyStatus()` — if no local `device_key` but Block Store key exists, return `blockStoreRecoveryAvailable`
- Add `generateBlockStoreDeviceKey()` — generates KeyDuo, stores in Block Store, returns KeyDuo
- Add `getBlockStoreDeviceKey()` — reads from Block Store, returns KeyDuo or null
- Add `deleteBlockStoreDeviceKey()` — removes from Block Store
- Modify `clearKeys()` — also delete `device_key_blockstore` from Block Store

### `lib/infrastructure/auth/auth_service.dart`
- Modify `createAccount()` — after registering local device, also generate and register Block Store device key (Android only)
- Add `recoverFromBlockStoreKey()` — implements Flow B (auth with Block Store key, recover symmetric key, register new local device)

### `lib/app/bootstrap.dart` or app router guard
- On launch, if `getKeyStatus()` returns `blockStoreRecoveryAvailable`, trigger `recoverFromBlockStoreKey()` instead of onboarding

### `lib/features/settings/cubits/device_management/device_management_cubit.dart`
- Modify `revokeDevice()` — if revoking the Block Store device AND platform is Android, also delete from Block Store
- Add `recreateBlockStoreKey()` — implements Flow D

### `lib/features/settings/widgets/device_list_section.dart`
- Show Block Store device with cloud/backup icon (detect by label "Google Backup")
- Add "Enable Google Backup" button if no Block Store device exists in the device list (Android only)

## Server Changes Needed

None. All existing endpoints support this flow. Same as iOS plan.

## Shared Code with iOS Plan

The flows are nearly identical — only the storage backend differs. Consider abstracting:

```dart
abstract class CrossDeviceKeyStorage {
  Future<void> store(String jwk);
  Future<String?> retrieve();
  Future<void> delete();
  bool get isAvailable;
  String get deviceLabel; // "iCloud" or "Google Backup"
}

class ICloudKeyStorage implements CrossDeviceKeyStorage { ... }
class BlockStoreKeyStorage implements CrossDeviceKeyStorage { ... }
```

Then `CryptoKeyRepository`, `AuthService`, and `DeviceManagementCubit` can be platform-agnostic — they just call the `CrossDeviceKeyStorage` interface. Platform selection happens at DI registration time.

## Edge Cases

1. **No Google Play Services** — Block Store is unavailable. `save()` / `retrieve()` fail. Graceful degradation: skip silently, user has local key + recovery phrase.
2. **Backup disabled** — Block Store stores locally but doesn't transfer cross-device. Same-device uninstall/reinstall still works. Cross-device doesn't. Acceptable.
3. **No screen lock (pre-Android 9 or no PIN)** — Block Store works but without E2E encryption. The key is still encrypted by Google Play Services, just not E2E. Acceptable for a device key (not the ultimate key).
4. **User deletes app from all devices** — Block Store data persists if Backup enabled. Reinstall on same or new device can recover via Flow B.
5. **Two new devices restored simultaneously** — Both call `registerDeviceForAccount` with unique local keys. Server handles fine. Both succeed.
6. **Block Store transfer timing** — Unlike iCloud Keychain, Block Store only transfers during device setup/restore. If user sets up device B, then creates account on device A, device B won't have the key until next device setup. Accepted limitation.
7. **Revoke Block Store key, device B already has it** — Device B tries to auth → server rejects (revoked) → device B falls back to onboarding.
8. **shouldBackupToCloud not respected** — Some Android OEMs may not fully support cloud backup for Block Store. Graceful degradation: cross-device won't work, but local key + recovery phrase still functional.
