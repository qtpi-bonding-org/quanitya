import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/infrastructure/platform/secure_preferences.dart';
import 'package:quanitya_flutter/infrastructure/purchase/entitlement_repository.dart';

import '../../helpers/fake_secure_storage.dart';

void main() {
  late FakeSecureStorage fakeStorage;
  late SecurePreferences prefs;
  late EntitlementRepository repo;

  setUp(() {
    fakeStorage = FakeSecureStorage();
    prefs = SecurePreferences(fakeStorage);
    repo = EntitlementRepository(prefs);
  });

  // -------------------------------------------------------------------------
  // load / store
  // -------------------------------------------------------------------------

  group('load', () {
    test('returns empty list when nothing is cached', () async {
      final result = await repo.load();
      expect(result, isEmpty);
    });

    test('stores and retrieves entitlements', () async {
      final entitlements = [
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 10.0,
          type: 'time_balance',
          name: '500 MB Sync Days',
        ),
        const CachedEntitlement(
          tag: 'premium_feature',
          balance: 1.0,
          type: 'feature_flag',
        ),
      ];

      await repo.store(entitlements);
      final loaded = await repo.load();

      expect(loaded.length, 2);
      expect(loaded[0].tag, 'sync_500mb_days');
      expect(loaded[0].balance, 10.0);
      expect(loaded[0].type, 'time_balance');
      expect(loaded[0].name, '500 MB Sync Days');
      expect(loaded[1].tag, 'premium_feature');
      expect(loaded[1].balance, 1.0);
      expect(loaded[1].type, 'feature_flag');
      expect(loaded[1].name, isNull);
    });

    test('store overwrites previously cached entitlements', () async {
      await repo.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 10.0,
          type: 'time_balance',
        ),
      ]);
      await repo.store([
        const CachedEntitlement(
          tag: 'sync_1gb_days',
          balance: 2.0,
          type: 'time_balance',
        ),
      ]);

      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded[0].tag, 'sync_1gb_days');
    });
  });

  // -------------------------------------------------------------------------
  // hasSyncAccess
  // -------------------------------------------------------------------------

  group('hasSyncAccess', () {
    test('returns true when sync_500mb_days balance > 0', () async {
      await repo.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 5.0,
          type: 'time_balance',
        ),
      ]);
      expect(await repo.hasSyncAccess(), isTrue);
    });

    test('returns true for sync_1gb_days tag', () async {
      await repo.store([
        const CachedEntitlement(
          tag: 'sync_1gb_days',
          balance: 3.0,
          type: 'time_balance',
        ),
      ]);
      expect(await repo.hasSyncAccess(), isTrue);
    });

    test('returns false when no sync entitlements present', () async {
      await repo.store([
        const CachedEntitlement(
          tag: 'premium_feature',
          balance: 1.0,
          type: 'feature_flag',
        ),
      ]);
      expect(await repo.hasSyncAccess(), isFalse);
    });

    test('returns false when sync balance is 0', () async {
      await repo.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 0.0,
          type: 'time_balance',
        ),
      ]);
      expect(await repo.hasSyncAccess(), isFalse);
    });

    test('returns false when cache is empty', () async {
      expect(await repo.hasSyncAccess(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // clear
  // -------------------------------------------------------------------------

  group('clear', () {
    test('removes all cached entitlements', () async {
      await repo.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 5.0,
          type: 'time_balance',
        ),
      ]);
      await repo.clear();
      expect(await repo.load(), isEmpty);
    });

    test('clear does not affect the purchased flag', () async {
      await repo.markPurchased();
      await repo.clear();
      expect(await repo.hasEverPurchased(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // hasEverPurchased / markPurchased
  // -------------------------------------------------------------------------

  group('hasEverPurchased', () {
    test('returns false when no purchase flag is set', () async {
      expect(await repo.hasEverPurchased(), isFalse);
    });

    test('returns true after markPurchased is called', () async {
      await repo.markPurchased();
      expect(await repo.hasEverPurchased(), isTrue);
    });

    test('markPurchased is idempotent — calling twice stays true', () async {
      await repo.markPurchased();
      await repo.markPurchased();
      expect(await repo.hasEverPurchased(), isTrue);
    });

    test('persists across repository instances (same prefs)', () async {
      await repo.markPurchased();
      final repo2 = EntitlementRepository(prefs);
      expect(await repo2.hasEverPurchased(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // updateBalance
  // -------------------------------------------------------------------------

  group('updateBalance', () {
    test('adds new entry when tag does not exist', () async {
      await repo.updateBalance('sync_500mb_days', 7.0);
      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded[0].tag, 'sync_500mb_days');
      expect(loaded[0].balance, 7.0);
    });

    test('updates existing entry balance', () async {
      await repo.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 10.0,
          type: 'time_balance',
          name: '500 MB',
        ),
      ]);

      await repo.updateBalance('sync_500mb_days', 3.0);

      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded[0].balance, 3.0);
      // Preserves existing metadata
      expect(loaded[0].type, 'time_balance');
      expect(loaded[0].name, '500 MB');
    });

    test('only updates the targeted tag — leaves others untouched', () async {
      await repo.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 10.0,
          type: 'time_balance',
        ),
        const CachedEntitlement(
          tag: 'sync_1gb_days',
          balance: 5.0,
          type: 'time_balance',
        ),
      ]);

      await repo.updateBalance('sync_500mb_days', 1.0);

      final loaded = await repo.load();
      expect(loaded.length, 2);
      final updated = loaded.firstWhere((e) => e.tag == 'sync_500mb_days');
      final unchanged = loaded.firstWhere((e) => e.tag == 'sync_1gb_days');
      expect(updated.balance, 1.0);
      expect(unchanged.balance, 5.0);
    });

    test('updateBalance to zero means hasSyncAccess returns false', () async {
      await repo.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 10.0,
          type: 'time_balance',
        ),
      ]);

      await repo.updateBalance('sync_500mb_days', 0.0);
      expect(await repo.hasSyncAccess(), isFalse);
    });
  });
}
