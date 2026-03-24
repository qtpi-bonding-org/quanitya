import 'package:drift/drift.dart' show QueryRow, Selectable;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:serverpod_client/serverpod_client.dart' show UuidValue;
import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;

import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/infrastructure/purchase/entitlement_repository.dart';
import 'package:quanitya_flutter/infrastructure/purchase/i_entitlement_service.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_state.dart';

class MockEntitlementService extends Mock implements IEntitlementService {}

class MockEntitlementRepository extends Mock implements EntitlementRepository {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockSelectable extends Mock implements Selectable<QueryRow> {}

class MockQueryRow extends Mock implements QueryRow {}

void main() {
  late MockEntitlementService mockService;
  late MockEntitlementRepository mockRepo;
  late MockAppDatabase mockDb;

  /// Stubs the methods that [EntitlementCubit._initialize] calls so that
  /// construction does not crash.  By default hasPurchased returns true so
  /// the full init path (load entitlements, sync access, storage) runs.
  void stubInitDefaults({bool hasPurchased = true}) {
    when(() => mockRepo.hasEverPurchased())
        .thenAnswer((_) async => hasPurchased);
    when(() => mockService.getEntitlements()).thenAnswer((_) async => []);
    when(() => mockService.hasSyncAccess()).thenAnswer((_) async => false);

    final mockRow = MockQueryRow();
    when(() => mockRow.read<int>('cnt')).thenReturn(0);
    when(() => mockRow.read<int>('total_bytes')).thenReturn(0);

    final mockSelectable = MockSelectable();
    when(() => mockSelectable.getSingle()).thenAnswer((_) async => mockRow);

    when(() => mockDb.customSelect(any())).thenReturn(mockSelectable);
  }

  /// Wait long enough for [_initialize] to complete.
  Future<void> waitForInit() =>
      Future.delayed(const Duration(milliseconds: 150));

  setUp(() {
    mockService = MockEntitlementService();
    mockRepo = MockEntitlementRepository();
    mockDb = MockAppDatabase();
    stubInitDefaults();
  });

  group('EntitlementCubit', () {
    test('loadEntitlements populates state with entitlements', () async {
      when(() => mockService.getEntitlements()).thenAnswer(
        (_) async => [
          AccountEntitlement(
            accountUuid: UuidValue.fromString(
                '00000000-0000-0000-0000-000000000001'),
            entitlementId: 1,
            balance: 25.0,
          ),
        ],
      );

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
      await waitForInit();

      // Init already called loadEntitlements; verify the result.
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.entitlements.length, 1);
      expect(cubit.state.entitlements.first.balance, 25.0);
      expect(cubit.state.hasPurchased, isTrue);

      // Calling it again should still work.
      await cubit.loadEntitlements();
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.lastOperation, EntitlementOperation.loadEntitlements);
      expect(cubit.state.entitlements.length, 1);
      expect(cubit.state.entitlements.first.balance, 25.0);

      await cubit.close();
    });

    test('checkSyncAccess emits true when service says yes', () async {
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => true);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
      await waitForInit();

      await cubit.checkSyncAccess();
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.lastOperation, EntitlementOperation.checkSyncAccess);
      expect(cubit.state.hasSyncAccess, isTrue);

      await cubit.close();
    });

    test('checkSyncAccess emits false when no credits', () async {
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => false);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
      await waitForInit();

      await cubit.checkSyncAccess();
      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.hasSyncAccess, isFalse);

      await cubit.close();
    });

    test('checkSyncAccess emits failure when service throws', () async {
      final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
      await waitForInit();

      // Override stub AFTER init completes so only the next call fails.
      when(() => mockService.hasSyncAccess())
          .thenThrow(Exception('Network error'));

      await cubit.checkSyncAccess();
      expect(cubit.state.status, UiFlowStatus.failure);
      expect(cubit.state.error, isNotNull);

      await cubit.close();
    });

    test('loadEntitlements returns empty list when service returns none',
        () async {
      when(() => mockService.getEntitlements())
          .thenAnswer((_) async => []);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
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
          AccountEntitlement(
            accountUuid: UuidValue.fromString(
                '00000000-0000-0000-0000-000000000001'),
            entitlementId: 1,
            balance: 10.0,
          ),
        ],
      );
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => true);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
      await waitForInit();

      expect(cubit.state.entitlements.length, 1);
      expect(cubit.state.hasSyncAccess, isTrue);
      expect(cubit.state.hasPurchased, isTrue);
      expect(cubit.state.storageBytes, 0);
      expect(cubit.state.entryCount, 0);

      await cubit.close();
    });

    test('initialization skips server calls when not purchased', () async {
      stubInitDefaults(hasPurchased: false);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
      await waitForInit();

      expect(cubit.state.hasPurchased, isFalse);
      expect(cubit.state.entitlements, isEmpty);
      verifyNever(() => mockService.getEntitlements());

      await cubit.close();
    });

    test('refreshIfStale fetches entitlements and updates sync access', () async {
      // Start with no sync access
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => false);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
      await waitForInit();
      expect(cubit.state.hasSyncAccess, isFalse);

      // Now simulate a purchase happened — server has sync entitlement
      when(() => mockService.getEntitlements()).thenAnswer(
        (_) async => [
          AccountEntitlement(
            accountUuid: UuidValue.fromString(
                '00000000-0000-0000-0000-000000000001'),
            entitlementId: 1,
            balance: 30.0,
          ),
        ],
      );
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => true);

      await cubit.refreshIfStale();

      expect(cubit.state.hasSyncAccess, isTrue);
      expect(cubit.state.entitlements.length, 1);
      expect(cubit.state.lastOperation, EntitlementOperation.refreshIfStale);
      verify(() => mockService.getEntitlements()).called(greaterThanOrEqualTo(2)); // init + refresh

      await cubit.close();
    });

    test('loadEntitlements also updates hasSyncAccess', () async {
      when(() => mockService.hasSyncAccess())
          .thenAnswer((_) async => true);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
      await waitForInit();

      // Init already ran loadEntitlements which now includes hasSyncAccess
      expect(cubit.state.hasSyncAccess, isTrue);
      expect(cubit.state.lastOperation, isNotNull);

      await cubit.close();
    });

    test('refreshIfStale skips when not purchased', () async {
      stubInitDefaults(hasPurchased: false);

      final cubit = EntitlementCubit(mockService, mockRepo, mockDb);
      await waitForInit();

      await cubit.refreshIfStale();

      // getEntitlements should not have been called (init skips it, refresh skips it)
      verifyNever(() => mockService.getEntitlements());

      await cubit.close();
    });
  });
}
