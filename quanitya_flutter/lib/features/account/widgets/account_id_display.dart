import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/widgets/quanitya_icon_button.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/account_info_cubit.dart';
import '../cubits/account_info_state.dart';

/// Displays the account's public key hex with a copy button.
///
/// Shows nothing if the key hasn't been loaded yet.
class AccountIdDisplay extends StatelessWidget {
  const AccountIdDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger load if not yet loaded
    context.read<AccountInfoCubit>().loadAccountInfo();

    return BlocBuilder<AccountInfoCubit, AccountInfoState>(
      builder: (context, state) {
        final keyHex = state.accountPublicKeyHex;
        if (keyHex == null) return const SizedBox.shrink();

        final palette = QuanityaPalette.primary;
        final truncated = '${keyHex.substring(0, 8)}...${keyHex.substring(keyHex.length - 8)}';

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.settingsAccountId,
                    style: context.text.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  VSpace.x025,
                  Text(
                    truncated,
                    style: context.text.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            QuanityaIconButton(
              icon: Icons.copy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: keyHex));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.copiedToClipboard),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: context.l10n.copyToClipboard,
            ),
          ],
        );
      },
    );
  }
}
