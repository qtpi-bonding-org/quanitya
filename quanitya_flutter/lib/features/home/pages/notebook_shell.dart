import 'package:flutter/material.dart';

import '../../../support/extensions/context_extensions.dart';
import '../../outbox/pages/outbox_page.dart';
import '../../outbox/widgets/folder_tab_bar.dart';
import '../../results/pages/results_section.dart';
import '../../office/pages/office_page.dart';
import 'temporal_home_page.dart';

/// Root-level shell that wraps all four major sections with a [FolderTabBar].
class NotebookShell extends StatefulWidget {
  const NotebookShell({super.key});

  @override
  State<NotebookShell> createState() => _NotebookShellState();
}

class _NotebookShellState extends State<NotebookShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      FolderTab(icon: Icons.auto_stories, label: context.l10n.tabLogbook),
      FolderTab(icon: Icons.insights, label: context.l10n.tabResults),
      FolderTab(icon: Icons.mail_outline, label: context.l10n.tabPostage),
      FolderTab(icon: Icons.desk, label: context.l10n.tabOffice),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const TemporalHomePage(),
                const ResultsSection(),
                // Postage (Notices + Feedback + Analytics + Errors)
                const PostagePage(),
                const OfficePage(),
              ],
            ),
          ),
          FolderTabBar(
            currentIndex: _currentIndex,
            onTabSelected: (index) => setState(() => _currentIndex = index),
            tabs: tabs,
          ),
        ],
      ),
    );
  }
}
