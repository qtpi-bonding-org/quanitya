import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/primitives/app_spacings.dart';
import '../../../design_system/widgets/quanitya/general/loose_insert_sheet.dart';
import '../../../design_system/widgets/quanitya/general/quanitya_text_button.dart';
import '../../../design_system/widgets/quanitya_text_field.dart';
import '../../../support/extensions/context_extensions.dart';
import '../cubits/recovery_key/recovery_key_cubit.dart';

/// Bottom sheet for importing a recovery key (JWK).
class ImportRecoveryKeySheet extends StatefulWidget {
  const ImportRecoveryKeySheet({super.key});

  /// Show the import recovery key sheet as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required RecoveryKeyCubit cubit,
  }) {
    return LooseInsertSheet.show(
      context: context,
      title: context.l10n.importRecoveryKeyTitle,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: const ImportRecoveryKeySheet(),
      ),
    );
  }

  @override
  State<ImportRecoveryKeySheet> createState() => _ImportRecoveryKeySheetState();
}

class _ImportRecoveryKeySheetState extends State<ImportRecoveryKeySheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
          VSpace.x4,

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              QuanityaTextButton(
                text: context.l10n.actionCancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
              HSpace.x2,
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
          ),
        ],
      ),
    );
  }
}
