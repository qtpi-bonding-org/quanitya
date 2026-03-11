import 'package:flutter/material.dart';

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

  static const _tabs = [
    FolderTab(icon: Icons.auto_stories, label: 'Logbook'),
    FolderTab(icon: Icons.insights, label: 'Results'),
    FolderTab(icon: Icons.mail_outline, label: 'Postage'),
    FolderTab(icon: Icons.work_outline, label: 'Office'),
  ];

  @override
  Widget build(BuildContext context) {
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
            tabs: _tabs,
          ),
        ],
      ),
    );
  }
}
