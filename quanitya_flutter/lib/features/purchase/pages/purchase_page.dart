import 'package:flutter/material.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../infrastructure/purchase/purchase_models.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/purchase_cubit.dart';
import '../cubits/purchase_state.dart';
import '../cubits/entitlement_cubit.dart';
import '../cubits/entitlement_state.dart';
import '../widgets/product_card.dart';
import '../widgets/balance_display.dart';

/// Purchase content — embedded in [NotebookShell] via OfficePage.
///
/// Expects [PurchaseCubit] and [EntitlementCubit] to be available via
/// [BlocProvider] above.
class PurchaseTabContent extends StatelessWidget {
  const PurchaseTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PurchaseCubit>().loadProducts();
        context.read<EntitlementCubit>()
          ..loadEntitlements()
          ..checkSyncAccess()
          ..loadStorageUsage();
      },
      child: ListView(
        padding: AppPadding.verticalSingle,
        children: [
          // Entitlement balance section
          BlocBuilder<EntitlementCubit, EntitlementState>(
            builder: (context, state) {
              return BalanceDisplay(
                entitlements: state.entitlements,
                hasSyncAccess: state.hasSyncAccess,
                storageBytes: state.storageBytes,
                entryCount: state.entryCount,
              );
            },
          ),

          VSpace.x2,

          // Products section
          BlocBuilder<PurchaseCubit, PurchaseState>(
            builder: (context, state) {
              if (state.status == UiFlowStatus.loading &&
                  state.lastOperation == PurchaseOperation.loadProducts) {
                return Center(
                  child: Padding(
                    padding: AppPadding.allTriple,
                    child: const CircularProgressIndicator(),
                  ),
                );
              }

              if (state.status == UiFlowStatus.failure &&
                  state.lastOperation == PurchaseOperation.loadProducts) {
                return Center(
                  child: Padding(
                    padding: AppPadding.allTriple,
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: context.colors.errorColor,
                        ),
                        VSpace.x1,
                        Text(
                          context.l10n.purchaseLoadFailed,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.errorColor,
                          ),
                        ),
                        VSpace.x2,
                        QuanityaTextButton(
                          text: context.l10n.actionRetry,
                          onPressed: () =>
                              context.read<PurchaseCubit>().loadProducts(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: AppPadding.allTriple,
                    child: Text(context.l10n.purchaseNoProducts),
                  ),
                );
              }

              final isPurchasing =
                  state.status == UiFlowStatus.loading &&
                      state.lastOperation == PurchaseOperation.purchase;

              return _ProductSections(
                products: state.products,
                isPurchasing: isPurchasing,
                onBuy: (product) => _onBuy(context, product),
              );
            },
          ),

          VSpace.x2,

          // Restore purchases
          Center(
            child: QuanityaTextButton(
              text: context.l10n.restorePurchases,
              onPressed: () =>
                  context.read<PurchaseCubit>().recoverPurchases(),
            ),
          ),

          // Validation result feedback
          BlocBuilder<PurchaseCubit, PurchaseState>(
            builder: (context, state) {
              final validation = state.lastValidation;
              if (validation == null) return const SizedBox.shrink();

              final palette = QuanityaPalette.primary;
              final feedbackColor = validation.success
                  ? palette.successColor
                  : palette.errorColor;

              return Padding(
                padding: AppPadding.pageHorizontal,
                child: Row(
                  children: [
                    Icon(
                      validation.success
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: feedbackColor,
                      size: AppSizes.iconSmall,
                    ),
                    HSpace.x1,
                    Expanded(
                      child: Text(
                        validation.success
                            ? context.l10n.purchaseSuccessful
                            : validation.errorMessage ??
                                context.l10n.purchaseFailed,
                        style: context.text.bodyMedium?.copyWith(
                          color: feedbackColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _onBuy(BuildContext context, PurchaseProduct product) {
    context.read<PurchaseCubit>().purchase(
          PurchaseRequest(
            productId: product.productId,
            rail: product.rail,
            accountId: 0, // Resolved server-side
          ),
        );
  }
}

/// Groups products by [StoreProductType] and renders each group
/// under a section header. Subscriptions are further split into
/// columns by [SubscriptionPeriod]. New product types or periods
/// added later automatically get their own section/column.
class _ProductSections extends StatelessWidget {
  const _ProductSections({
    required this.products,
    required this.isPurchasing,
    required this.onBuy,
  });

  final List<PurchaseProduct> products;
  final bool isPurchasing;
  final void Function(PurchaseProduct) onBuy;

  static const _typeOrder = [
    StoreProductType.subscription,
    StoreProductType.consumable,
  ];

  @override
  Widget build(BuildContext context) {
    final grouped = <StoreProductType, List<PurchaseProduct>>{};
    for (final product in products) {
      (grouped[product.productType] ??= []).add(product);
    }

    for (final list in grouped.values) {
      list.sort((a, b) => a.priceUsd.compareTo(b.priceUsd));
    }

    final sections = <MapEntry<StoreProductType, List<PurchaseProduct>>>[];
    for (final type in _typeOrder) {
      final products = grouped[type];
      if (products != null) {
        sections.add(MapEntry(type, products));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          Padding(
            padding: AppPadding.pageHorizontal,
            child: Text(
              _sectionTitle(context, section.key),
              style: context.text.titleLarge,
            ),
          ),
          VSpace.x1,
          if (section.key == StoreProductType.subscription)
            _buildSubscriptionColumns(context, section.value)
          else
            Padding(
              padding: AppPadding.pageHorizontal,
              child: Wrap(
                spacing: AppSizes.space * 2,
                runSpacing: AppSizes.space * 2,
                children: section.value
                    .map((product) => SizedBox(
                          width: AppSizes.space * 20,
                          child: ProductCard(
                            product: product,
                            isLoading: isPurchasing,
                            onBuy: () => onBuy(product),
                          ),
                        ))
                    .toList(),
              ),
            ),
          VSpace.x2,
        ],
      ],
    );
  }

  /// Splits subscriptions into Monthly / Yearly columns.
  /// Subscriptions without a detected period go below as a flat
  /// price-sorted list.
  Widget _buildSubscriptionColumns(
    BuildContext context,
    List<PurchaseProduct> subscriptions,
  ) {
    final monthly = subscriptions
        .where((p) => p.subscriptionPeriod == SubscriptionPeriod.monthly)
        .toList();
    final yearly = subscriptions
        .where((p) => p.subscriptionPeriod == SubscriptionPeriod.yearly)
        .toList();
    final rest = subscriptions
        .where((p) => p.subscriptionPeriod == null)
        .toList();

    return Column(
      children: [
        // Monthly / Yearly columns (only if both have products).
        if (monthly.isNotEmpty && yearly.isNotEmpty)
          Padding(
            padding: AppPadding.pageHorizontal,
            child: LayoutGroup.row(
              minChildWidth: 20,
              children: [
                _PeriodColumn(
                  title: context.l10n.purchasePeriodMonthly,
                  products: monthly,
                  isPurchasing: isPurchasing,
                  onBuy: onBuy,
                ),
                HSpace.x1,
                _PeriodColumn(
                  title: context.l10n.purchasePeriodYearly,
                  products: yearly,
                  isPurchasing: isPurchasing,
                  onBuy: onBuy,
                ),
              ],
            ),
          )
        // Only one period exists — flat list.
        else
          ...monthly.followedBy(yearly).map((product) => ProductCard(
                product: product,
                isLoading: isPurchasing,
                onBuy: () => onBuy(product),
              )),
        // Unknown period — flat list sorted by price.
        ...rest.map((product) => ProductCard(
              product: product,
              isLoading: isPurchasing,
              onBuy: () => onBuy(product),
            )),
      ],
    );
  }

  String _sectionTitle(BuildContext context, StoreProductType type) {
    return switch (type) {
      StoreProductType.subscription => context.l10n.purchaseSectionSubscriptions,
      StoreProductType.consumable => context.l10n.purchaseSectionConsumables,
      _ => context.l10n.purchaseSectionSubscriptions,
    };
  }
}

class _PeriodColumn extends StatelessWidget {
  const _PeriodColumn({
    required this.title,
    required this.products,
    required this.isPurchasing,
    required this.onBuy,
  });

  final String title;
  final List<PurchaseProduct> products;
  final bool isPurchasing;
  final void Function(PurchaseProduct) onBuy;

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Column(
      children: [
        Text(
          title,
          style: context.text.titleSmall?.copyWith(
            color: palette.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        VSpace.x1,
        ...products.map((product) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.space * 2),
              child: ProductCard(
                product: product,
                isLoading: isPurchasing,
                onBuy: () => onBuy(product),
              ),
            )),
      ],
    );
  }
}
