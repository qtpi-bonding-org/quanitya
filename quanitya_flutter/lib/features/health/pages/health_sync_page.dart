import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';

import '../../../integrations/flutter/health/health_sync_cubit.dart';
import '../../../integrations/flutter/health/health_sync_state.dart';

/// Default health data types to sync.
const _defaultHealthTypes = [
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.BODY_TEMPERATURE,
  HealthDataType.WEIGHT,
];

class HealthSyncPage extends StatelessWidget {
  const HealthSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<HealthSyncCubit>(),
      child: const _HealthSyncView(),
    );
  }
}

class _HealthSyncView extends StatelessWidget {
  const _HealthSyncView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Health Sync',
          style: context.text.headlineMedium,
        ),
        leading: QuanityaIconButton(
          icon: Icons.arrow_back,
          onPressed: () => AppNavigation.back(context),
        ),
      ),
      body: Padding(
        padding: AppPadding.page,
        child: BlocBuilder<HealthSyncCubit, HealthSyncState>(
          builder: (context, state) {
            return ListView(
              children: [
                // Status section
                Text(
                  'PERMISSIONS',
                  style: context.text.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                VSpace.x1,
                Text(
                  state.permissionsGranted
                      ? 'Health data access granted'
                      : 'Health data access not yet requested',
                  style: context.text.bodyMedium?.copyWith(
                    color: state.permissionsGranted
                        ? context.colors.successColor
                        : context.colors.textSecondary,
                  ),
                ),
                VSpace.x3,

                QuanityaTextButton(
                  text: 'Request Permissions',
                  onPressed: state.status == UiFlowStatus.loading
                      ? null
                      : () => context
                          .read<HealthSyncCubit>()
                          .requestPermissions(_defaultHealthTypes),
                ),
                VSpace.x4,

                // Sync section
                Text(
                  'SYNC',
                  style: context.text.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                VSpace.x1,
                Text(
                  state.lastImportCount > 0
                      ? '${state.lastImportCount} entries imported'
                      : 'No data synced yet',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                VSpace.x3,

                QuanityaTextButton(
                  text: 'Sync Health Data',
                  onPressed: state.status == UiFlowStatus.loading
                      ? null
                      : () => context
                          .read<HealthSyncCubit>()
                          .sync(_defaultHealthTypes),
                ),

                // Loading indicator
                if (state.status == UiFlowStatus.loading) ...[
                  VSpace.x4,
                  const Center(child: CircularProgressIndicator()),
                ],

                // Error display
                if (state.status == UiFlowStatus.failure &&
                    state.error != null) ...[
                  VSpace.x4,
                  Text(
                    state.error.toString(),
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.errorColor,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
