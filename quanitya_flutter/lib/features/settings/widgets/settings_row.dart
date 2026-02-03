import 'package:flutter/material.dart';
import '../../../../design_system/structures/row.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../support/extensions/context_extensions.dart';

class SettingsRow extends StatelessWidget {
  final String label;
  final Widget control;

  const SettingsRow({
    super.key,
    required this.label,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    return QuanityaRow(
      alignment: CrossAxisAlignment.center,
      spacing: HSpace.x2,
      middle: Text(
        label,
        style: context.text.bodyLarge, // 16px
      ),
      end: control,
    );
  }
}
