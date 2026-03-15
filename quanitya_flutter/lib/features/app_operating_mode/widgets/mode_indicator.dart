import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../cubits/app_operating_cubit.dart';
import '../cubits/app_operating_state.dart';
import '../models/app_operating_mode.dart';

/// Displays a small icon indicating the current server connection status.
///
/// Hidden in local mode. Shows cloud/server icon colored by connection state:
/// - Sage green ([stateOn]) when connected
/// - Caution amber when disconnected
class ModeIndicator extends StatelessWidget {
  const ModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppOperatingCubit, AppOperatingState>(
      buildWhen: (prev, curr) =>
          prev.mode != curr.mode || prev.isConnected != curr.isConnected,
      builder: (context, state) {
        if (state.mode == AppOperatingMode.local) {
          return const SizedBox.shrink();
        }

        final palette = QuanityaPalette.primary;
        final color = state.isConnected
            ? palette.stateOnColor
            : palette.cautionColor;

        final icon = switch (state.mode) {
          AppOperatingMode.cloud => Icons.cloud,
          AppOperatingMode.selfHosted => Icons.dns,
          AppOperatingMode.local => Icons.cloud, // unreachable
        };

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.space),
          child: Icon(
            icon,
            color: color,
            size: AppSizes.iconSmall,
          ),
        );
      },
    );
  }
}
