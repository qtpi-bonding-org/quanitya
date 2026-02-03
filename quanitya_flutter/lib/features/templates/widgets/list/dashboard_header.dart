import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_fonts.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Format: 2023 10 24
    final dateStr = DateFormat('yyyy MM dd').format(_now);
    // Format: 09:41:30
    final timeStr = DateFormat('hh:mm:ss').format(_now);

    return Column(
      children: [
        Text(
          dateStr,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontFamily: QuanityaFonts.headerFamily,
            color: theme.colorScheme.onSurface, // Sumi Black
            fontWeight: FontWeight.bold,
          ),
        ),
        VSpace.x1,
        Text(
          timeStr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: QuanityaFonts.bodyFamily,
            color: theme.colorScheme.secondary, // Neutral/Draft
            fontWeight: FontWeight.normal,
            fontFeatures: [const FontFeature.tabularFigures()], // Prevent jitter
          ),
        ),
      ],
    );
  }
}
