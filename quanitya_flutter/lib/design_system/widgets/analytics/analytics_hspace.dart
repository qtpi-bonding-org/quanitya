import 'package:flutter/material.dart';
import '../../primitives/analytics_grid.dart';

/// Horizontal spacing for analytics components that aligns to zen grid
/// 
/// Provides semantic spacing constructors for consistent analytics layouts.
/// All spacing values are multiples of the base zen paper grid (24px).
/// 
/// Complements AnalyticsVSpace for complete grid-aligned layout control.
class AnalyticsHSpace extends StatelessWidget {
  final double width;
  
  const AnalyticsHSpace(this.width, {super.key});
  
  /// Semantic constructors aligned to zen grid
  AnalyticsHSpace.small({super.key}) : width = AnalyticsGrid.unit1;   // 24px
  AnalyticsHSpace.medium({super.key}) : width = AnalyticsGrid.unit2;  // 48px
  AnalyticsHSpace.large({super.key}) : width = AnalyticsGrid.unit3;   // 72px
  AnalyticsHSpace.xlarge({super.key}) : width = AnalyticsGrid.unit4;  // 96px
  
  @override
  Widget build(BuildContext context) => SizedBox(width: width);
}