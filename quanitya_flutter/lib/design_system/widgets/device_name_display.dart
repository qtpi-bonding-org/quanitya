import 'package:flutter/material.dart';

import '../primitives/app_spacings.dart';
import '../primitives/app_sizes.dart';
import '../primitives/quanitya_palette.dart';
import '../structures/column.dart';
import '../../support/extensions/context_extensions.dart';

/// Displays the device name in a centered, styled container.
/// 
/// Used across onboarding and pairing flows to show the auto-detected
/// device name in a consistent, visually appealing way.
class DeviceNameDisplay extends StatelessWidget {
  final String label;
  final String deviceName;

  const DeviceNameDisplay({
    super.key,
    required this.label,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: ${deviceName.isNotEmpty ? deviceName : '...'}',
      child: QuanityaColumn(
        spacing: VSpace.x2,
        crossAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: context.text.bodyLarge,
            textAlign: TextAlign.center,
          ),
          Container(
            padding: AppPadding.allDouble,
            decoration: BoxDecoration(
              color: context.colors.textSecondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Text(
              deviceName.isNotEmpty ? deviceName : '...',
              style: context.text.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
