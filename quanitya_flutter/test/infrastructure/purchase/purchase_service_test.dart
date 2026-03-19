import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart' show Client;

import 'package:quanitya_flutter/infrastructure/platform/platform_capability_service.dart';
import 'package:quanitya_flutter/infrastructure/public_submission/public_submission_service.dart';
import 'package:quanitya_flutter/infrastructure/purchase/i_purchase_provider.dart';
import 'package:quanitya_flutter/infrastructure/purchase/purchase_exception.dart';
import 'package:quanitya_flutter/infrastructure/purchase/purchase_models.dart';
import 'package:quanitya_flutter/infrastructure/purchase/purchase_service.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/models/app_syncing_mode.dart';

class MockPurchaseProvider extends Mock implements IPurchaseProvider {}

class MockPublicSubmissionService extends Mock
    implements PublicSubmissionService {}

class MockClient extends Mock implements Client {}

class MockPlatformCapabilityService extends Mock
    implements PlatformCapabilityService {}

void main() {
  late PurchaseService purchaseService;
  late MockPurchaseProvider mockProvider;
  late MockPublicSubmissionService mockSubmissionService;
  late MockClient mockClient;
  late MockPlatformCapabilityService mockPlatformCaps;

  setUpAll(() {
    registerFallbackValue(
      const PurchaseRequest(
        productId: '',
        rail: PurchaseRail.appleIap,
      ),
    );
    registerFallbackValue(
      const PurchaseResult(
        status: PurchaseStatus.success,
        rail: PurchaseRail.appleIap,
        productId: '',
      ),
    );
    registerFallbackValue(AppSyncingMode.cloud);
  });

  setUp(() {
    mockProvider = MockPurchaseProvider();
    mockSubmissionService = MockPublicSubmissionService();
    mockClient = MockClient();
    mockPlatformCaps = MockPlatformCapabilityService();
    purchaseService = PurchaseService(
      mockSubmissionService,
      mockClient,
      mockPlatformCaps,
    );
  });

  group('PurchaseService', () {
    test('registerProvider adds provider and getProducts returns its products',
        () async {
      when(() => mockProvider.rail).thenReturn(PurchaseRail.appleIap);
      when(() => mockProvider.getAvailableProducts()).thenAnswer(
        (_) async => [
          const PurchaseProduct(
            productId: 'sync_1gb_month',
            title: 'Monthly Sync (1 GB)',
            description: '1 month of cloud sync (1 GB)',
            priceUsd: 3.99,
            rail: PurchaseRail.appleIap,
          ),
        ],
      );

      purchaseService.registerProvider(mockProvider);
      final products = await purchaseService.getProducts();

      expect(products, hasLength(1));
      expect(products.first.productId, 'sync_1gb_month');
      expect(products.first.priceUsd, 3.99);
    });

    test('getProducts with rail filter returns only matching products',
        () async {
      when(() => mockProvider.rail).thenReturn(PurchaseRail.appleIap);
      when(() => mockProvider.getAvailableProducts()).thenAnswer(
        (_) async => [
          const PurchaseProduct(
            productId: 'sync_1gb_month',
            title: 'Monthly Sync (1 GB)',
            description: '1 month of sync',
            priceUsd: 3.99,
            rail: PurchaseRail.appleIap,
          ),
        ],
      );

      purchaseService.registerProvider(mockProvider);

      // Matching rail returns products
      final apple = await purchaseService.getProducts(rail: PurchaseRail.appleIap);
      expect(apple, hasLength(1));

      // Non-matching rail returns empty
      final google =
          await purchaseService.getProducts(rail: PurchaseRail.googleIap);
      expect(google, isEmpty);
    });

    test('purchase happy path: initiate → validate', () async {
      when(() => mockProvider.rail).thenReturn(PurchaseRail.appleIap);
      when(() => mockProvider.initiatePurchase(any())).thenAnswer(
        (_) async => const PurchaseResult(
          status: PurchaseStatus.success,
          rail: PurchaseRail.appleIap,
          productId: 'sync_1gb_month',
          transactionId: 'txn_123',
        ),
      );
      when(() => mockProvider.validateWithServer(any())).thenAnswer(
        (_) async => const PurchaseValidationResult(
          success: true,
          tag: 'sync_days',
          amount: 30,
        ),
      );

      purchaseService.registerProvider(mockProvider);

      final result = await purchaseService.purchase(
        const PurchaseRequest(
          productId: 'sync_1gb_month',
          rail: PurchaseRail.appleIap,
        ),
        mode: AppSyncingMode.cloud,
      );

      expect(result.success, isTrue);
      expect(result.tag, 'sync_days');
      expect(result.amount, 30);
    });

    test('purchase throws PurchaseException when store purchase is cancelled', () async {
      when(() => mockProvider.rail).thenReturn(PurchaseRail.appleIap);
      when(() => mockProvider.initiatePurchase(any())).thenAnswer(
        (_) async => const PurchaseResult(
          status: PurchaseStatus.cancelled,
          rail: PurchaseRail.appleIap,
          productId: 'sync_1gb_month',
        ),
      );

      purchaseService.registerProvider(mockProvider);

      expect(
        () => purchaseService.purchase(
          const PurchaseRequest(
            productId: 'sync_1gb_month',
            rail: PurchaseRail.appleIap,
          ),
          mode: AppSyncingMode.cloud,
        ),
        throwsA(isA<PurchaseException>()),
      );
    });

    test('purchase throws PurchaseException for unregistered rail', () async {
      expect(
        () => purchaseService.purchase(
          const PurchaseRequest(
            productId: 'sync_1gb_month',
            rail: PurchaseRail.monero,
          ),
          mode: AppSyncingMode.cloud,
        ),
        throwsA(isA<PurchaseException>()),
      );
    });

    test('getDefaultProvider returns first available provider', () async {
      when(() => mockProvider.rail).thenReturn(PurchaseRail.appleIap);
      when(() => mockProvider.isAvailable()).thenAnswer((_) async => true);

      purchaseService.registerProvider(mockProvider);
      final provider = await purchaseService.getDefaultProvider();

      expect(provider, isNotNull);
      expect(provider!.rail, PurchaseRail.appleIap);
    });

    test('getDefaultProvider returns null when no providers available',
        () async {
      final provider = await purchaseService.getDefaultProvider();
      expect(provider, isNull);
    });
  });
}
