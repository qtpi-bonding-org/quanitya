# Silent Catch Block Analysis

## Summary
- 10 blocks -> captureError (non-fatal, intentionally terminal)
- 2 blocks -> remove catch / let propagate (should fail the operation)
- 11 blocks -> leave as-is (correct fallback behavior)

---

## Option A: Add ErrorPrivserver.captureError

### 1. `lib/infrastructure/auth/account_service.dart:185` — cross-device key setup during registration

**Context:** Inside `createAccount()`, the cross-device key generation/attestation/storage is wrapped in a try-catch inside a `if (isCrossDeviceStorageAvailable)` block. On failure, the registration continues without cross-device key support. The outer method is wrapped in `tryMethod`.

**Why captureError:** This is genuinely non-fatal (registration succeeds without cross-device keys), but a failure here means the user silently loses multi-device capability. Worth recording so developers can see if a platform consistently fails cross-device key setup.

### 2. `lib/infrastructure/auth/account_service.dart:339` — cross-device key server registration

**Context:** Inside `registerAccountWithServer()` (wrapped in `tryMethod`), after the primary device registration succeeds, the cross-device key is registered with the server. Failure is caught and logged. The method continues to `setRegistered()`.

**Why captureError:** Same rationale as #1. The user loses cross-device sync capability silently. This is a server call failure that could indicate auth/network issues worth tracking, but should not block the primary registration flow.

### 3. `lib/infrastructure/auth/delete_service.dart:73` — cross-device key deletion

**Context:** Inside `deleteAccount()` (wrapped in `tryMethod`), after the server-side account deletion succeeds, the local cross-device key is deleted. Failure is caught because the key may not exist. Processing continues to clear registration flag, entitlements, and disconnect PowerSync.

**Why captureError:** If the key exists but deletion fails for a non-trivial reason (e.g., keychain error), that is worth recording. The "key may not exist" case would produce a specific error type that could be filtered, but the catch-all hides real keychain failures.

### 9. `lib/infrastructure/purchase/providers/in_app_purchase_repository.dart:380` — Apple reconciliation per-item

**Context:** Inside `_reconcileAppleSubscriptions()`, each SK2 transaction is validated with the server in a loop. The outer method is called from `reconcileSubscriptionEntitlements()` which is wrapped in `tryMethod`. One transaction failure should not stop processing others.

**Why captureError:** A per-transaction server validation failure during reconciliation is a real problem (could mean lost entitlements). The loop pattern is correct (don't stop others), but these failures should be visible for debugging subscription issues.

### 10. `lib/infrastructure/purchase/providers/in_app_purchase_repository.dart:421` — Google reconciliation per-item

**Context:** Same pattern as #9 but for Google Play subscriptions. Each past purchase is re-validated with the server independently.

**Why captureError:** Same rationale as #9. Per-item purchase validation failures during reconciliation are worth recording for debugging entitlement issues.

### 11. `lib/infrastructure/purchase/providers/in_app_purchase_repository.dart:544` — orphan recovery outer catch

**Context:** `_recoverOrphanedPurchase()` is called from `_handlePurchaseUpdates()` (a stream listener) when a purchase notification arrives with no pending completer. The outer catch handles `validateWithServer` failure. On failure, it still tries to `completePurchase` to clear the platform queue.

**Why captureError:** Orphan recovery failures mean the user paid but the entitlement was not granted AND the recovery mechanism failed. This is a critical business event worth recording. There is no cubit in the call chain (it comes from a stream listener).

### 12. `lib/infrastructure/purchase/providers/in_app_purchase_repository.dart:554` — orphan recovery inner completePurchase

**Context:** Nested inside the outer catch of #11. After `validateWithServer` fails, `completePurchase` is called to clear the platform purchase queue. If this also fails, it is silently caught.

**Why captureError:** A `completePurchase` failure means the platform will keep re-delivering this purchase notification, causing a retry loop. Worth recording to understand if users get stuck in purchase limbo.

### 13. `lib/infrastructure/webhooks/webhook_service.dart:62` — triggerWebhooks load error

**Context:** `_triggerForTemplateAsync()` is a fire-and-forget method (called via `unawaited`). It loads enabled webhooks for a template, then fires each. The catch handles the DB load failure. There is no cubit in the call chain.

**Why captureError:** A DB read failure for webhooks is unexpected and indicates a real problem. While fire-and-forget is the correct pattern, total webhook load failure (not just one webhook failing) is worth recording.

### 14. `lib/infrastructure/webhooks/webhook_service.dart:71` — _fireWebhookSafe fire error

**Context:** `_fireWebhookSafe()` wraps a single webhook HTTP call. Called in a loop from `_triggerForTemplateAsync()`. No cubit in the call chain.

**Why captureError:** Individual webhook failures (network errors, 4xx/5xx) are worth recording. The user configured these webhooks and has no way to know they are silently failing unless they check manually. This gives developers visibility into webhook reliability.

### 18. `lib/logic/schedules/services/schedule_generator_service.dart:122` — per-schedule generation

**Context:** Inside `generatePendingTodos()` (wrapped in `tryMethod`), each active schedule is processed in a loop. Failed schedule IDs are collected into `failedIds` and returned in the `GenerationResult`. One failure should not stop other schedules.

**Why captureError:** The method already tracks failures in `failedIds`, but those only surface if the caller inspects the result. The actual exception (which could be a DB error, recurrence parsing error, etc.) is lost. Recording via captureError preserves the exception details for debugging.

---

## Option B: Remove catch / let propagate

### 15. `lib/integrations/flutter/health/health_sync_service.dart:103` — syncIfEnabled

**Context:** `syncIfEnabled()` checks if health sync is enabled and has permissions, then calls `sync()`. The entire method is wrapped in a bare try-catch that swallows all errors. This method is called from two places: (a) the app lifecycle resume hook, and (b) directly.

**Why propagate:** The resume-hook caller already has its own `catchError` (item #5), so propagation from `syncIfEnabled` would be caught there. But when called directly (e.g., from a cubit), this silent catch prevents the cubit from knowing sync failed. **However**, looking more carefully: `syncIfEnabled` is ONLY called from resume hooks (line 78 and 92), never from a cubit directly. The resume hook already catches errors. **Revised: Option A** -- this should use captureError since it is only called from fire-and-forget resume hooks with no cubit in the chain, but sync failures (e.g., HealthKit API errors) are worth recording.

### 17. `lib/logic/analytics/analytics_service.dart:143` — sendAllUnsent batch

**Context:** `sendAllUnsent()` sends analytics events in batches of 100. Per-batch failures are caught and cause a `break` (stop sending further batches). This method is called from: (a) `bootstrap.dart` with its own try-catch, and (b) `analytics_cubit.dart` via `tryOperation`. The cubit caller wraps it in `tryOperation`, which expects exceptions to propagate for UI feedback.

**Why propagate:** When the analytics cubit calls `sendAll()` -> `sendAllUnsent()`, the user expects to see success/failure feedback. The silent catch means the cubit always sees "success" (returns `totalSent` which could be 0 or partial). The cubit should know if sending failed so it can show an error. The `break` is fine for partial success, but the method should throw after the loop if any batch failed, so the cubit can report it. **Recommendation:** Keep the per-batch catch but throw after the loop if `totalSent < allEvents.length`, so partial failures propagate to the cubit.

---

## Option C: Leave as-is

### 4. `lib/infrastructure/device/device_info_service.dart:38` — getDeviceName fallback

**Context:** `getDeviceName()` tries to get the device name from platform APIs. On failure, it falls back to `_getFallbackName()` which returns a generic name like "iPhone" or "Android". The fallback is always valid.

**Why leave:** This is the correct "try with fallback" pattern. The device name is cosmetic (used for device labels). Platform API failures (e.g., missing permissions on some Android OEMs) are expected and the fallback is the right UX. Recording this error would be pure noise.

### 5. `lib/infrastructure/platform/app_lifecycle_service.dart:36` — resume hook catchError

**Context:** `_handleResume()` iterates over registered callbacks and calls each with `.catchError()`. Each callback runs independently. This is a fire-and-forget dispatcher.

**Why leave:** This is the correct pattern for a lifecycle resume dispatcher. Each callback is independent and already has its own error handling (the callbacks themselves, like `syncIfEnabled`, handle their own errors). If those callbacks gain captureError (per #15 revised), this outer catch is just a safety net and adds no value to capture again. The dispatcher should not crash if one callback fails.

### 6. `lib/infrastructure/permissions/permission_service.dart:61` — ensureHealth (requestHealth)

**Context:** `ensureHealth()` requests HealthKit/Health Connect authorization. On platform exception, it returns `false` (permission not granted). The caller (a cubit) gets `false` and treats it as "not granted."

**Why leave:** Platform permission APIs can throw for many reasons (missing entitlements, Health Connect not installed, etc.). Returning `false` is the correct UX -- the user sees "permission not granted" and can try again or check settings. These platform exceptions are expected and environment-specific, not bugs.

### 7. `lib/infrastructure/permissions/permission_service.dart:79` — hasHealth

**Context:** `hasHealth()` checks current health permission status. On exception, returns `false`. The `hasPermissions` API from the health package can throw on unsupported platforms.

**Why leave:** Same rationale as #6. Checking permission status is a query that should degrade gracefully. Returning `false` means "treat as not granted," which is the safe default.

### 8. `lib/infrastructure/permissions/permission_service.dart:101` — _ensure

**Context:** `_ensure()` is the internal method for requesting a single permission (notification, camera, location). On exception, returns `false`.

**Why leave:** Same rationale as #6 and #7. Permission APIs are inherently platform-dependent and can throw for environment reasons. The callers (cubits) interpret `false` as "not granted" and show appropriate UI. These are not bugs.

### 16. `lib/logic/analytics/analytics_service.dart:90` — _track save to inbox

**Context:** `_track()` saves an analytics event to the local inbox. Uses `.then().catchError()` pattern (fire-and-forget). The `_track` method is `void` (not `Future<void>`), so there is no caller to propagate to.

**Why leave:** Analytics tracking is explicitly fire-and-forget (the class doc says "Tracking methods are fire-and-forget -- they never throw or block"). A local DB write failure for analytics should not affect the user's workflow. The event is just lost, which is acceptable for optional analytics.

### 19. `lib/logic/templates/services/shared/dynamic_field_builder.dart:671` — location capture button

**Context:** Inside a widget's `onPressed` callback, `LocationService.captureCurrentPosition()` is called. On failure (permission denied, GPS unavailable), the catch block just debugPrints. The button simply does nothing on failure.

**Why leave:** This is a UI interaction where the user tapped "Capture Location." If location fails, the field just stays empty -- the user can see nothing happened and try again. Showing a toast/error would be better UX but that is a feature enhancement, not an error handling fix. The catch preventing a crash is correct. A `captureError` here would record known permission/GPS failures which are user-environment issues, not bugs.

### 20. `lib/logic/schedules/services/recurrence_service.dart:82` — getOccurrences

**Context:** `getOccurrences()` parses an RRULE and calculates occurrences. If `tryParse` succeeds but `getInstances()` throws (e.g., malformed rule edge case), returns empty list.

**Why leave:** This is a pure computation method called from the schedule generator. Returning an empty list means "no occurrences to generate" which is safe -- the schedule just produces no todos for this period. The RRULE library can throw on edge cases with valid-looking but semantically broken rules. The caller (schedule generator) handles "no occurrences" gracefully.

### 21. `lib/logic/schedules/services/recurrence_service.dart:104` — getNextOccurrences

**Context:** Same pattern as #20 but for getting the next N occurrences. Returns empty list on error.

**Why leave:** Same rationale as #20. Empty list is a safe fallback for recurrence calculation failures.

### 22. `lib/logic/schedules/services/recurrence_service.dart:123` — toHumanReadable

**Context:** Converts an RRULE to human-readable text. On failure, returns the raw RRULE string as fallback.

**Why leave:** The method already has a well-designed fallback (show the raw string). This is a display-only method where showing the raw RRULE is acceptable degraded UX. The catch handles a known limitation (l10n/toText issues noted in the comment).

### 23. `lib/data/repositories/e2ee_puller.dart:87` — per-record decryption failure

**Context:** `processEncryptedRecords()` iterates over encrypted records and decrypts each. On per-record failure, it logs and continues to the next record. One corrupted/undecryptable record should not block processing the rest.

**Why leave:** **Actually, this should be Option A.** A decryption failure means a user's data record is permanently inaccessible (likely a key mismatch or corrupted ciphertext). This is a serious data integrity issue that developers need to know about. The loop-continue pattern is correct, but the error should be captured.

---

## Revised Summary

After analysis, revising the counts:

- **11 blocks -> captureError** (non-fatal, intentionally terminal, worth recording)
  - #1, #2, #3, #9, #10, #11, #12, #13, #14, #18, #23
  - Also #15 (revised from Option B -- only called from resume hooks, no cubit path)
- **1 block -> remove catch / let propagate**
  - #17 (analytics batch send -- cubit caller needs to know about failures)
- **10 blocks -> leave as-is**
  - #4, #5, #6, #7, #8, #16, #19, #20, #21, #22

## Final Counts
- 12 blocks -> captureError
- 1 block -> remove catch / let propagate
- 10 blocks -> leave as-is

---

## Detailed Recommendations

### captureError additions (12)

| # | File | Method | Error Severity |
|---|------|--------|---------------|
| 1 | `account_service.dart:185` | cross-device key setup | medium -- user silently loses multi-device |
| 2 | `account_service.dart:339` | cross-device key server registration | medium -- user silently loses multi-device |
| 3 | `delete_service.dart:73` | cross-device key deletion | low -- orphaned key, cleanup issue |
| 9 | `in_app_purchase_repository.dart:380` | Apple reconciliation per-item | high -- potential lost entitlement |
| 10 | `in_app_purchase_repository.dart:421` | Google reconciliation per-item | high -- potential lost entitlement |
| 11 | `in_app_purchase_repository.dart:544` | orphan recovery outer | critical -- user paid, entitlement not granted |
| 12 | `in_app_purchase_repository.dart:554` | orphan recovery completePurchase | high -- stuck purchase retry loop |
| 13 | `webhook_service.dart:62` | webhook load failure | medium -- all webhooks silently broken |
| 14 | `webhook_service.dart:71` | single webhook fire failure | medium -- user's configured webhook silently broken |
| 15 | `health_sync_service.dart:103` | syncIfEnabled | low -- background sync failed, user unaware |
| 18 | `schedule_generator_service.dart:122` | per-schedule generation | medium -- scheduled todos silently not created |
| 23 | `e2ee_puller.dart:87` | per-record decryption | high -- user data permanently inaccessible |

### Propagation change (1)

| # | File | Method | Change |
|---|------|--------|--------|
| 17 | `analytics_service.dart:143` | sendAllUnsent batch | Keep per-batch catch + break, but after the loop, throw if `totalSent < allEvents.length` so the cubit caller sees partial failure |

### Leave as-is (10)

| # | File | Method | Reason |
|---|------|--------|--------|
| 4 | `device_info_service.dart:38` | getDeviceName | correct try-with-fallback pattern |
| 5 | `app_lifecycle_service.dart:36` | resume catchError | safety-net dispatcher, callbacks handle own errors |
| 6 | `permission_service.dart:61` | ensureHealth | platform permission API, false is correct fallback |
| 7 | `permission_service.dart:79` | hasHealth | platform permission query, false is correct fallback |
| 8 | `permission_service.dart:101` | _ensure | platform permission API, false is correct fallback |
| 16 | `analytics_service.dart:90` | _track save to inbox | fire-and-forget by design, void return |
| 19 | `dynamic_field_builder.dart:671` | location capture button | UI interaction, user sees nothing happened |
| 20 | `recurrence_service.dart:82` | getOccurrences | pure computation, empty list is safe fallback |
| 21 | `recurrence_service.dart:104` | getNextOccurrences | pure computation, empty list is safe fallback |
| 22 | `recurrence_service.dart:123` | toHumanReadable | display-only, raw string is acceptable fallback |
