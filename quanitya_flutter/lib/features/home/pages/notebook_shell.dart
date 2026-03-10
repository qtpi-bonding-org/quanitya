import 'package:flutter/material.dart';

import '../../outbox/widgets/folder_tab_bar.dart';
import 'temporal_home_page.dart';

/// Root-level shell that wraps all five major sections with a [FolderTabBar].
///
/// Acts as the physical notebook: Logbook, Results, Inbox, Outbox, Settings
/// are divider tabs along the bottom edge.
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
    FolderTab(icon: Icons.inbox, label: 'Inbox'),
    FolderTab(icon: Icons.outbox, label: 'Outbox'),
    FolderTab(icon: Icons.settings, label: 'Settings'),
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
              children: const [
                TemporalHomePage(),
                Placeholder(),
                Placeholder(),
                Placeholder(),
                Placeholder(),
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
