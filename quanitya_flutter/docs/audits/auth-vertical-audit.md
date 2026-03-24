# Auth Vertical Audit

## Summary

The auth vertical is largely well-structured: `tryMethod` wraps nearly all public service methods, exception types are properly defined and chained, and the PoW challenge flow is implemented correctly. However, four `!` (null-bang) operator usages in `account_service.dart` violate the explicit-null-check rule, two private helpers in `public_submission_service.dart` leak raw error messages into exception strings (PII/privacy concern per `tryMethod` design), `AccountService.ensureRegistered` is a public method that bypasses `tryMethod`, and `AuthAccountOrchestrator` passes a meaningless hardcoded `'auto'` label for device re-registration.

---

## Violations Found

### 1. Null-Bang (`!`) Operator Usage

- [ ] **account_service.dart:661** — `publicKeyHex: callerKeyHex!` — `callerKeyHex` is the result of `getDeviceSigningPublicKeyHex()` which returns `String?`. If null, this throws an untyped `Null check operator used on a null value` crash with no diagnostic context. **Rule violated:** "Never use `!` operator — use explicit null checks with typed exceptions." **Fix:** Check `callerKeyHex` for null immediately after retrieval (just as is done elsewhere in the same method, e.g., lines 633–639) and throw `AccountRecoveryException('Device public key not available after generation')`.

- [ ] **account_service.dart:722** — `publicKeyHex: cdCallerKeyHex!` — Same pattern in `recreateCrossDeviceKey`. `cdCallerKeyHex` is fetched on line 714 and used as `!` on line 722 with no prior null check. **Rule violated:** Same as above. **Fix:** Add an explicit null check after line 714 and throw `AuthException('Device public key not available')`.

- [ ] **account_service.dart:774** — `publicKeyHex: pubKeyHex!` — In `listDevices`, `pubKeyHex` is fetched on line 767. A null check exists for the sign payload on line 769, but `pubKeyHex` itself is passed as a non-null arg with `!` to the server call. **Rule violated:** Same as above. **Fix:** Add a null guard before line 769 (`if (pubKeyHex == null) throw AuthException(...)`) and remove the `!` on line 774.

- [ ] **account_service.dart:803** — `publicKeyHex: pubKeyHex!` — Same issue in `revokeDevice` on line 800. **Rule violated:** Same as above. **Fix:** Same pattern — null-check `pubKeyHex` after retrieval and throw `AuthException('Device public key not available')`.

---

### 2. Public Method Bypasses `tryMethod`

- [ ] **account_service.dart:357–360** — `ensureRegistered` is a public method that does not use `tryMethod`. If `_authRepo.isRegisteredWithServer` throws, the raw `AuthRepositoryException` propagates untyped to callers. The orchestrator (`auth_account_orchestrator.dart:44`) calls this method inside its own `tryMethod`, so it is partially caught, but `ensureRegistered` itself violates the layer contract. **Rule violated:** "Wrap all public service/repo methods with `tryMethod`." **Fix:** Wrap the body in `tryMethod(() async { ... }, (msg, [cause]) => AccountCreationException(msg, cause: cause), 'ensureRegistered')`.

---

### 3. Raw Error Messages Leaked Through Exception Strings

- [ ] **public_submission_service.dart:180** — `_getChallenge` catches bare `Object e` and re-throws `PublicSubmissionException('Failed to get challenge: $e')`. This interpolates the raw exception (which may contain server response details, stack fragments, or PII) directly into the exception message, bypassing `tryMethod`'s privacy-safe `SafeExceptionCause` wrapper. **Rule violated:** "Privacy Note: Only method names and exception types are included in error messages." **Fix:** Replace the `try/catch` with `tryMethod` (or remove it — `_getChallenge` is private and already called inside a `tryMethod` scope; the catch in the outer `tryMethod` will handle typing). If a private helper is kept, re-throw a typed exception without interpolating `$e`: `throw PublicSubmissionException('getChallenge failed')`.

- [ ] **public_submission_service.dart:197** — `_mineProofOfWork` does the same: `throw PublicSubmissionException('Failed to mine proof-of-work: $e')`. Same privacy leak. **Rule violated:** Same as above. **Fix:** Same — do not interpolate `$e` into the message.

- [ ] **public_submission_service.dart:237** — `_signPayload` does the same: `throw PublicSubmissionException('Failed to sign payload: $e')`. **Rule violated:** Same as above. **Fix:** Same.

---

### 4. Hardcoded Meaningless Device Label for Re-Registration

- [ ] **auth_account_orchestrator.dart:44** — `await _accountService.ensureRegistered(deviceLabel: 'auto')` — When a device is re-registered after being revoked, the label stored on the server becomes the literal string `'auto'`, providing zero identification value to the user when reviewing their device list. **Rule violated:** No explicit coding guideline, but this is a semantic correctness issue: the device label should identify the device (e.g., via `DeviceInfoService`). **Fix:** Inject `DeviceInfoService` into `AuthAccountOrchestrator` and derive the label from device model/name (e.g., `await _deviceInfoService.getDeviceLabel()`).

---

### 5. `storeAuthSession` Silently Returns on Missing Fields

- [ ] **auth_service.dart:99–107** — The top-level `storeAuthSession` function returns silently (without throwing) if `details` is null or if `token`/`authUserIdStr` are null. When the server returns an `AuthenticationResult` with `success: true` but missing session details, the caller (`authenticateDevice`) believes authentication succeeded — but no JWT is stored, leaving subsequent authenticated requests to fail with 401s rather than a typed `DeviceAuthenticationException`. **Rule violated:** "Never fail silently — errors must propagate or be explicitly handled." **Fix:** Throw a `DeviceAuthenticationException('Authentication response missing session details')` when `details == null` or required fields are absent, rather than returning silently.

---

### 6. `createAccount` Server Response Not Checked

- [ ] **account_service.dart:278–290** — `_client.modules.anonaccount.account.createAccount(...)` is awaited but its return value is ignored (the method presumably returns an `AuthenticationResult` or similar typed response). If the server indicates failure in the response body (rather than throwing a `ServerException`), the failure is silently ignored and the flow continues to mark the device as registered. **Rule violated:** "Never ignore return values from server calls." **Fix:** Capture the return value and check `result.success` (or equivalent), throwing `AccountCreationException(result.errorMessage ?? 'Account creation failed on server')` if false.

---

## Clean Files

The following files have no violations against the audited rules:

- `lib/infrastructure/auth/auth_repository.dart` — All public methods use `tryMethod` with `AuthRepositoryException`, no `!` operators, no silent catches.
- `lib/infrastructure/auth/delete_service.dart` — Both public methods use `tryMethod`; the single bare `catch` on the cross-device key deletion is intentional and documented as non-critical with an explicit `debugPrint`.
- `lib/infrastructure/auth/local_auth_service.dart` — All public methods use `tryMethod`; the inner `on PlatformException` catch is a legitimate discriminator returning a typed enum value rather than swallowing errors.
- `lib/infrastructure/auth/registration_payload.dart` — Pure data class, no async logic.
- `lib/infrastructure/crypto/data_encryption_service.dart` — All `IDataEncryption` methods use `tryMethod`; private helpers `_getSymmetricKey` and `_getDeviceKeyDuo` use explicit null checks with typed exceptions instead of `!`.
- `lib/infrastructure/crypto/interfaces/i_secure_storage.dart` — Interface only; no implementation logic to audit.
- `lib/infrastructure/crypto/exceptions/crypto_exceptions.dart` — Exception definitions only.
