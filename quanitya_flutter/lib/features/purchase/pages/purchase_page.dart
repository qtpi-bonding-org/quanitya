import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../infrastructure/purchase/purchase_models.dart';
import '../cubits/purchase_cubit.dart';
import '../cubits/purchase_state.dart';
import '../cubits/entitlement_cubit.dart';
import '../cubits/entitlement_state.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../support/extensions/context_extensions.dart';
import '../widgets/product_card.dart';
import '../widgets/balance_display.dart';

/// Purchase page showing available products and entitlement balances.
class PurchasePage extends StatelessWidget {
  const PurchasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.instance<PurchaseCubit>()..loadProducts(),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<EntitlementCubit>()
            ..loadEntitlements()
            ..checkSyncAccess(),
        ),
      ],
      child: const _PurchaseView(),
    );
  }
}

class _PurchaseView extends StatelessWidget {
  const _PurchaseView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.purchaseTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<PurchaseCubit>().loadProducts();
          context.read<EntitlementCubit>().loadEntitlements();
          context.read<EntitlementCubit>().checkSyncAccess();
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
                );
              },
            ),

            VSpace.x2,

            // Products section
            Padding(
              padding: AppPadding.pageHorizontal,
              child: Text(
                context.l10n.purchaseAvailableProducts,
                style: context.text.titleLarge,
              ),
            ),
            VSpace.x1,

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

                if (state.products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: AppPadding.allTriple,
                      child: Text(context.l10n.purchaseNoProducts),
                    ),
                  );
                }

                return Column(
                  children: state.products.map((product) {
                    final isPurchasing =
                        state.status == UiFlowStatus.loading &&
                            state.lastOperation == PurchaseOperation.purchase;

                    return ProductCard(
                      product: product,
                      isLoading: isPurchasing,
                      onBuy: () => _onBuy(context, product),
                    );
                  }).toList(),
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

                return Padding(
                  padding: AppPadding.allDouble,
                  child: Card(
                    color: validation.success
                        ? context.colors.successColor.withValues(alpha: 0.1)
                        : context.colors.errorColor.withValues(alpha: 0.1),
                    child: Padding(
                      padding: AppPadding.allDouble,
                      child: Text(
                        validation.success
                            ? context.l10n.purchaseSuccessful
                            : validation.errorMessage ?? context.l10n.purchaseFailed,
                        style: context.text.bodyMedium?.copyWith(
                          color: validation.success
                              ? context.colors.successColor
                              : context.colors.errorColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onBuy(BuildContext context, PurchaseProduct product) {
    // accountId is resolved server-side during validation, using 0 as placeholder
    // The real accountId comes from authenticateDevice() in the provider
    context.read<PurchaseCubit>().purchase(
          PurchaseRequest(
            productId: product.productId,
            rail: product.rail,
            accountId: 0, // Resolved server-side
          ),
        );
  }
}
