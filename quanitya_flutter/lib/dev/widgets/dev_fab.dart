import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design_system/primitives/quanitya_palette.dart';
import 'dev_tools_sheet.dart';

/// Development FAB that only shows in debug mode.
/// 
/// Provides quick access to dev tools like data seeding,
/// clearing data, and navigation shortcuts.
class DevFab extends StatelessWidget {
  /// Set to true during golden screenshot tests to hide the FAB.
  static bool hideForScreenshots = false;

  const DevFab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || hideForScreenshots) return const SizedBox.shrink();

    final palette = QuanityaPalette.primary;
    
    return FloatingActionButton.small(
      onPressed: () => showDevToolsSheet(context),
      backgroundColor: palette.interactableColor,
      child: Icon(
        Icons.developer_mode,
        color: palette.backgroundPrimary,
      ),
    );
  }
}