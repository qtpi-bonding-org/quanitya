import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/infrastructure/platform/secure_preferences.dart';
import 'package:quanitya_flutter/infrastructure/purchase/entitlement_cache.dart';

import '../../helpers/fake_secure_storage.dart';

void main() {
  late FakeSecureStorage fakeStorage;
  late SecurePreferences prefs;
  late EntitlementCache cache;

  setUp(() {
    fakeStorage = FakeSecureStorage();
    prefs = SecurePreferences(fakeStorage);
    cache = EntitlementCache(prefs);
  });

  group('EntitlementCache', () {
    test('load returns empty list when nothing is cached', () async {
      final result = await cache.load();
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

      await cache.store(entitlements);
      final loaded = await cache.load();

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

    test('hasSyncAccess returns true when sync balance > 0', () async {
      await cache.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 5.0,
          type: 'time_balance',
        ),
      ]);

      expect(await cache.hasSyncAccess(), isTrue);
    });

    test('hasSyncAccess returns true for 1gb sync tag', () async {
      await cache.store([
        const CachedEntitlement(
          tag: 'sync_1gb_days',
          balance: 3.0,
          type: 'time_balance',
        ),
      ]);

      expect(await cache.hasSyncAccess(), isTrue);
    });

    test('hasSyncAccess returns false when no sync entitlements', () async {
      await cache.store([
        const CachedEntitlement(
          tag: 'premium_feature',
          balance: 1.0,
          type: 'feature_flag',
        ),
      ]);

      expect(await cache.hasSyncAccess(), isFalse);
    });

    test('hasSyncAccess returns false when sync balance is 0', () async {
      await cache.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 0.0,
          type: 'time_balance',
        ),
      ]);

      expect(await cache.hasSyncAccess(), isFalse);
    });

    test('hasSyncAccess returns false when cache is empty', () async {
      expect(await cache.hasSyncAccess(), isFalse);
    });

    test('clear removes all cached entitlements', () async {
      await cache.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 5.0,
          type: 'time_balance',
        ),
      ]);

      await cache.clear();

      final loaded = await cache.load();
      expect(loaded, isEmpty);
    });

    test('store overwrites previously cached entitlements', () async {
      await cache.store([
        const CachedEntitlement(
          tag: 'sync_500mb_days',
          balance: 10.0,
          type: 'time_balance',
        ),
      ]);

      await cache.store([
        const CachedEntitlement(
          tag: 'sync_1gb_days',
          balance: 2.0,
          type: 'time_balance',
        ),
      ]);

      final loaded = await cache.load();
      expect(loaded.length, 1);
      expect(loaded[0].tag, 'sync_1gb_days');
    });
  });
}
