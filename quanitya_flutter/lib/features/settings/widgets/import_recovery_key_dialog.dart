import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../support/extensions/context_extensions.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/app_sizes.dart';
import '../../../../design_system/primitives/quanitya_fonts.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../cubits/recovery_key/recovery_key_cubit.dart';

/// Dialog for importing a recovery key (JWK).
class ImportRecoveryKeyDialog extends StatefulWidget {
  const ImportRecoveryKeyDialog({super.key});

  @override
  State<ImportRecoveryKeyDialog> createState() => _ImportRecoveryKeyDialogState();
}

class _ImportRecoveryKeyDialogState extends State<ImportRecoveryKeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.l10n.importRecoveryKeyTitle,
        style: context.text.titleLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.importRecoveryKeyMessage,
            style: context.text.bodyMedium,
          ),
          VSpace.x2,
          QuanityaTextField(
            controller: _controller,
            maxLines: 5,
            hintText: context.l10n.importRecoveryKeyHint,
          ),
        ],
      ),
      actions: [
        QuanityaTextButton(
          text: context.l10n.actionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        QuanityaTextButton(
          text: context.l10n.import_,
          onPressed: () {
            final jwk = _controller.text.trim();
            if (jwk.isNotEmpty) {
              context.read<RecoveryKeyCubit>().validateRecoveryKey(jwk);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
