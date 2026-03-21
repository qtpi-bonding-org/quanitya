import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quanitya_flutter/design_system/primitives/quanitya_date_format.dart';
import '../../../../design_system/primitives/app_spacings.dart';
import '../../../../design_system/primitives/quanitya_fonts.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader>
    with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = DateTime.now();
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _now = DateTime.now();
      _startTimer();
    } else if (state == AppLifecycleState.paused) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Format: 2023 10 24
    final dateStr = QuanityaDateFormat.full(_now);
    final timeStr = QuanityaDateFormat.timePrecise(_now);

    return Column(
      children: [
        Text(
          dateStr,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontFamily: QuanityaFonts.headerFamily,
            color: theme.colorScheme.onSurface, // Sumi Black
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
