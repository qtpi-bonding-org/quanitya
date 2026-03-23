import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/multi_ui_flow_listener.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/ui_flow_listener.dart';
import '../../../infrastructure/purchase/purchase_models.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../app_syncing_mode/cubits/app_syncing_cubit.dart';
import '../../app_syncing_mode/models/app_syncing_mode.dart';
import '../cubits/entitlement_cubit.dart';
import '../cubits/paid_account_cubit.dart';
import '../cubits/entitlement_message_mapper.dart';
import '../cubits/entitlement_state.dart';
import '../cubits/purchase_cubit.dart';
import '../cubits/purchase_message_mapper.dart';
import '../cubits/purchase_state.dart';
import '../widgets/entitlement_display.dart';
import '../../sync_status/widgets/sync_status_indicator.dart';
import '../widgets/consumable_card.dart';
import '../widgets/product_card.dart';

/// Purchase content — embedded in [NotebookShell] via OfficePage.
///
/// Expects [PurchaseCubit] and [EntitlementCubit] to be available via
/// [BlocProvider] above.
class PurchaseTabContent extends StatelessWidget {
  const PurchaseTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiUiFlowListener(
      listeners: [
        (child) => UiFlowListener<PurchaseCubit, PurchaseState>(
              mapper: GetIt.instance<PurchaseMessageMapper>(),
              child: child,
            ),
        (child) => UiFlowListener<EntitlementCubit, EntitlementState>(
              mapper: GetIt.instance<EntitlementMessageMapper>(),
              child: child,
            ),
      ],
      child: BlocListener<PurchaseCubit, PurchaseState>(
        listenWhen: (prev, curr) =>
            curr.lastOperation == PurchaseOperation.purchase &&
            curr.status == UiFlowStatus.success &&
            prev.status != curr.status,
        listener: (context, state) {
          // Mark as paid account (persists flag for entitlement UI)
          context.read<PaidAccountCubit>().markPurchased();

          // Switch to cloud mode after successful purchase
          final syncCubit = context.read<AppSyncingCubit>();
          if (syncCubit.state.mode == AppSyncingMode.local) {
            syncCubit.switchToCloud();
          }
          // Refresh entitlements
          context.read<EntitlementCubit>()
            ..loadEntitlements(mode: AppSyncingMode.cloud)
            ..checkSyncAccess(mode: AppSyncingMode.cloud)
            ..loadStorageUsage(mode: AppSyncingMode.cloud);
        },
        child: RefreshIndicator(
        onRefresh: () async {
          context.read<PurchaseCubit>().loadProducts();
          if (context.read<PaidAccountCubit>().hasPurchased) {
            final mode = context.read<AppSyncingCubit>().state.mode;
            context.read<EntitlementCubit>()
              ..loadEntitlements(mode: mode)
              ..checkSyncAccess(mode: mode)
              ..loadStorageUsage(mode: mode);
          }
        },
        child: ListView(
          padding: AppPadding.verticalSingle,
          children: [
            const SyncStatusIndicator(),
            VSpace.x1,

            // Entitlement balance section (only if user has ever purchased)
            BlocBuilder<PaidAccountCubit, bool>(
              builder: (context, hasPurchased) {
                if (!hasPurchased) return const SizedBox.shrink();
                return BlocBuilder<EntitlementCubit, EntitlementState>(
                  builder: (context, state) {
                    final mode = context.read<AppSyncingCubit>().state.mode;
                    return EntitlementDisplay(
                      entitlements: state.entitlements,
                      storageBytes: state.storageBytes,
                      entryCount: state.entryCount,
                      hasError: state.hasError && mode.requiresServer,
                      onRetry: () {
                        context.read<EntitlementCubit>().loadEntitlements(mode: mode);
                      },
                    );
                  },
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

                return _ProductSections(
                  products: state.products,
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
            VSpace.x3,
          ],
        ),
      ),
      ),
    );
  }

  void _onBuy(BuildContext context, PurchaseProduct product) {
    final mode = context.read<AppSyncingCubit>().state.mode;
    context.read<PurchaseCubit>().purchase(
          PurchaseRequest(
            productId: product.productId,
            rail: product.rail,
          ),
          mode: mode,
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
    required this.onBuy,
  });

  final List<PurchaseProduct> products;
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

    final hasSubscriptions =
        sections.any((s) => s.key == StoreProductType.subscription);

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
                          child: ConsumableCard(
                            product: product,
                            onBuy: () => onBuy(product),
                          ),
                        ))
                    .toList(),
              ),
            ),
          VSpace.x2,
          if (section.key == StoreProductType.subscription)
            const _SubscriptionDisclosure(),
        ],
        if (!hasSubscriptions)
          // No subscription section rendered — still show disclosure
          // if subscriptions may load later. Omit in this case.
          const SizedBox.shrink(),
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
                  onBuy: onBuy,
                ),
                HSpace.x1,
                _PeriodColumn(
                  title: context.l10n.purchasePeriodYearly,
                  products: yearly,
                  onBuy: onBuy,
                ),
              ],
            ),
          )
        // Only one period exists — flat list.
        else
          ...monthly.followedBy(yearly).map((product) => ProductCard(
                product: product,
                onBuy: () => onBuy(product),
              )),
        // Unknown period — flat list sorted by price.
        ...rest.map((product) => ProductCard(
              product: product,
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
    required this.onBuy,
  });

  final String title;
  final List<PurchaseProduct> products;
  final void Function(PurchaseProduct) onBuy;

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;

    return Column(
      children: [
        Text(
          title,
          style: context.text.titleMedium?.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        VSpace.x1,
        ...products.map((product) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.space * 2),
              child: ProductCard(
                product: product,
                onBuy: () => onBuy(product),
              ),
            )),
      ],
    );
  }
}

/// Apple-required subscription disclosure text with links to
/// Privacy Policy and Terms of Service.
class _SubscriptionDisclosure extends StatefulWidget {
  const _SubscriptionDisclosure();

  @override
  State<_SubscriptionDisclosure> createState() =>
      _SubscriptionDisclosureState();
}

class _SubscriptionDisclosureState extends State<_SubscriptionDisclosure> {
  static const _privacyUrl = 'https://quanitya.com/#privacy';
  static const _termsUrl = 'https://quanitya.com/#terms';

  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl(_privacyUrl);
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl(_termsUrl);
  }

  @override
  void dispose() {
    _privacyRecognizer.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = QuanityaPalette.primary;
    final baseStyle = context.text.bodySmall?.copyWith(
      color: palette.textSecondary,
    );
    final linkStyle = baseStyle?.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: palette.textSecondary,
    );

    return Padding(
      padding: AppPadding.pageHorizontal,
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: context.l10n.subscriptionDisclosure),
            const TextSpan(text: '\n\n'),
            TextSpan(
              text: context.l10n.subscriptionDisclosurePrivacyPolicy,
              style: linkStyle,
              recognizer: _privacyRecognizer,
            ),
            const TextSpan(text: '  ·  '),
            TextSpan(
              text: context.l10n.subscriptionDisclosureTermsOfService,
              style: linkStyle,
              recognizer: _termsRecognizer,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
