import 'package:anonaccred_client/anonaccred_client.dart' show EntitlementType;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart'
    show AccountFeatureEntitlement, Feature;

import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/infrastructure/auth/auth_repository.dart';
import 'package:quanitya_flutter/infrastructure/purchase/entitlement_repository.dart';
import 'package:quanitya_flutter/infrastructure/purchase/i_entitlement_service.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_state.dart';

class MockEntitlementService extends Mock implements IEntitlementService {}

class MockEntitlementRepository extends Mock implements EntitlementRepository {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockAuthRepository extends Mock implements AuthRepository {}


void main() {
  late MockEntitlementService mockService;
  late MockEntitlementRepository mockRepo;
  late MockAppDatabase mockDb;
  late MockAuthRepository mockAuthRepo;

  /// Stubs the methods that [EntitlementCubit._initialize] calls so that
  /// construction does not crash.  By default hasPurchased returns true so
  /// the full init path (load entitlements, sync access, storage) runs.
  void stubInitDefaults({bool hasPurchased = true}) {
    when(() => mockRepo.hasEverPurchased())
        .thenAnswer((_) async => hasPurchased);
    when(() => mockService.getEntitlements()).thenAnswer((_) async => []);
    when(() => mockService.hasSyncAccess()).thenAnswer((_) async => false);
    when(() => mockService.hasAiAccess()).thenAnswer((_) async => false);

    when(() => mockDb.watchEncryptedStorageUsage())
        .thenAnswer((_) => Stream.value((count: 0, bytes: 0)));

    when(() => mockAuthRepo.isRegisteredWithServer)
        .thenAnswer((_) async => true);
  }

  /// Wait long enough for [_initialize] to complete.
  Future<void> waitForInit() =>
      Future.delayed(const Duration(milliseconds: 150));

  setUp(() {
    mockService = MockEntitlementService();
    mockRepo = MockEntitlementRepository();
    mockDb = MockAppDatabase();
    mockAuthRepo = MockAuthRepository();
    stubInitDefaults();
  });

  group('EntitlementCubit', () {
    test('loadEntitlements populates state with entitlements', () async {
      when(() => mockService.getEntitlements()).thenAnswer(
        (_) async => [
          AccountFeatureEntitlement(
            tag: 'sync_500mb_days',
            feature: Feature.cloudSync,
            type: EntitlementType.subscription,
            balance: 25.0,
          ),
        ],
      );

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb, mockAuthRepo);
      await waitForInit();

      // Init already called loadEntitlements; verify the result.
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.entitlements.length, 1);
      expect(cubit.state.entitlements.first.balance, 25.0);
      expect(cubit.state.hasPurchased, isTrue);

      // Calling it again should still work and include sync access.
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => true);
      when(() => mockService.hasAiAccess())
          .thenAnswer((_) async => false);
      await cubit.loadEntitlements();
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.lastOperation, EntitlementOperation.loadEntitlements);
      expect(cubit.state.entitlements.length, 1);
      expect(cubit.state.entitlements.first.balance, 25.0);
      expect(cubit.state.hasSyncAccess, isTrue);

      await cubit.close();
    });

    test('loadEntitlements returns empty list when service returns none',
        () async {
      when(() => mockService.getEntitlements())
          .thenAnswer((_) async => []);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb, mockAuthRepo);
      await waitForInit();

      await cubit.loadEntitlements();
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.entitlements, isEmpty);

      await cubit.close();
    });

    test('initialization loads entitlements, sync access, and storage',
        () async {
      when(() => mockService.getEntitlements()).thenAnswer(
        (_) async => [
          AccountFeatureEntitlement(
            tag: 'sync_500mb_days',
            feature: Feature.cloudSync,
            type: EntitlementType.subscription,
            balance: 10.0,
          ),
        ],
      );
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => true);
      when(() => mockService.hasAiAccess())
          .thenAnswer((_) async => false);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb, mockAuthRepo);
      await waitForInit();

      expect(cubit.state.entitlements.length, 1);
      expect(cubit.state.hasSyncAccess, isTrue);
      expect(cubit.state.hasPurchased, isTrue);
      expect(cubit.state.storageBytes, 0);
      expect(cubit.state.entryCount, 0);

      await cubit.close();
    });

    test('initialization fetches entitlements even when not marked as purchased', () async {
      stubInitDefaults(hasPurchased: false);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb, mockAuthRepo);
      await waitForInit();

      // Server returned empty entitlements, so hasPurchased stays false
      expect(cubit.state.hasPurchased, isFalse);
      expect(cubit.state.entitlements, isEmpty);
      // But the server call was still made (handles reinstall recovery)
      verify(() => mockService.getEntitlements()).called(1);

      await cubit.close();
    });

    test('initialization recovers hasPurchased when server has entitlements', () async {
      stubInitDefaults(hasPurchased: false);
      // Server knows about the purchase even though local cache was wiped
      when(() => mockService.getEntitlements()).thenAnswer(
        (_) async => [
          AccountFeatureEntitlement(
            tag: 'sync_500mb_days',
            feature: Feature.cloudSync,
            type: EntitlementType.subscription,
            balance: 30.0,
          ),
        ],
      );
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => true);
      when(() => mockService.hasAiAccess())
          .thenAnswer((_) async => false);
      when(() => mockRepo.markPurchased()).thenAnswer((_) async {});

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb, mockAuthRepo);
      await waitForInit();

      expect(cubit.state.hasPurchased, isTrue);
      expect(cubit.state.entitlements.length, 1);
      expect(cubit.state.hasSyncAccess, isTrue);
      verify(() => mockRepo.markPurchased()).called(1);

      await cubit.close();
    });

    test('refreshIfStale fetches entitlements and updates sync access', () async {
      // Start with no sync access
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => false);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb, mockAuthRepo);
      await waitForInit();
      expect(cubit.state.hasSyncAccess, isFalse);

      // Now simulate a purchase happened — server has sync entitlement
      when(() => mockService.getEntitlements()).thenAnswer(
        (_) async => [
          AccountFeatureEntitlement(
            tag: 'sync_500mb_days',
            feature: Feature.cloudSync,
            type: EntitlementType.subscription,
            balance: 30.0,
          ),
        ],
      );
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => true);
      when(() => mockService.hasAiAccess())
          .thenAnswer((_) async => false);

      await cubit.refreshIfStale();

      expect(cubit.state.hasSyncAccess, isTrue);
      expect(cubit.state.entitlements.length, 1);
      expect(cubit.state.lastOperation, EntitlementOperation.refreshIfStale);
      verify(() => mockService.getEntitlements()).called(greaterThanOrEqualTo(2)); // init + refresh

      await cubit.close();
    });

    test('refreshIfStale skips when not purchased', () async {
      stubInitDefaults(hasPurchased: false);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb, mockAuthRepo);
      await waitForInit();

      // Init called getEntitlements once (reinstall recovery).
      // refreshIfStale should NOT call it again since hasPurchased is still false.
      await cubit.refreshIfStale();

      verify(() => mockService.getEntitlements()).called(1); // only from init
      await cubit.close();
    });
  });
}
