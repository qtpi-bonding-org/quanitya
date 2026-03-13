import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_models.freezed.dart';
part 'purchase_models.g.dart';

/// The payment rail used for a purchase.
enum PurchaseRail { appleIap, googleIap, monero, x402Http }

/// Whether the store manages the purchase UI or the app does.
enum PurchaseUiMode { storeManaged, appManaged }

/// Status of a purchase attempt.
enum PurchaseStatus { success, pending, cancelled, failed, alreadyOwned }

/// Product type as reported by the store.
enum StoreProductType { consumable, subscription, unknown }

/// Subscription billing period as reported by the store.
enum SubscriptionPeriod { monthly, yearly }

/// A product available for purchase.
@freezed
class PurchaseProduct with _$PurchaseProduct {
  const factory PurchaseProduct({
    required String productId,
    required String title,
    required String description,
    required double priceUsd,
    required PurchaseRail rail,
    @Default(StoreProductType.unknown) StoreProductType productType,
    SubscriptionPeriod? subscriptionPeriod,
    String? localizedPrice,
    String? currencyCode,
  }) = _PurchaseProduct;

  factory PurchaseProduct.fromJson(Map<String, dynamic> json) =>
      _$PurchaseProductFromJson(json);
}

/// A request to purchase a product.
@freezed
class PurchaseRequest with _$PurchaseRequest {
  const factory PurchaseRequest({
    required String productId,
    required PurchaseRail rail,
    String? internalTransactionId,
  }) = _PurchaseRequest;

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) =>
      _$PurchaseRequestFromJson(json);
}

/// The result of a purchase attempt from the store.
@freezed
class PurchaseResult with _$PurchaseResult {
  const factory PurchaseResult({
    required PurchaseStatus status,
    required PurchaseRail rail,
    required String productId,
    String? transactionId,
    String? purchaseToken,
    String? packageName,
    Map<String, dynamic>? metadata,
    String? errorMessage,
  }) = _PurchaseResult;

  factory PurchaseResult.fromJson(Map<String, dynamic> json) =>
      _$PurchaseResultFromJson(json);
}

/// The result of server-side validation of a purchase.
@freezed
class PurchaseValidationResult with _$PurchaseValidationResult {
  const factory PurchaseValidationResult({
    required bool success,
    String? productId,
    String? tag,
    double? amount,
    String? errorMessage,
  }) = _PurchaseValidationResult;

  factory PurchaseValidationResult.fromJson(Map<String, dynamic> json) =>
      _$PurchaseValidationResultFromJson(json);
}
