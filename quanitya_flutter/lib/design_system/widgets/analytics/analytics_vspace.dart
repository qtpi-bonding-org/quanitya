import 'package:flutter/material.dart';
import '../../primitives/analytics_grid.dart';

/// Vertical spacing for analytics components that aligns to zen grid
/// 
/// Provides semantic spacing constructors for consistent analytics layouts.
/// All spacing values are multiples of the base zen paper grid (16px).
class AnalyticsVSpace extends StatelessWidget {
  final double height;
  
  const AnalyticsVSpace(this.height, {super.key});
  
  /// Semantic constructors
  AnalyticsVSpace.small({super.key}) : height = AnalyticsGrid.unit1;
  AnalyticsVSpace.medium({super.key}) : height = AnalyticsGrid.unit2;
  AnalyticsVSpace.large({super.key}) : height = AnalyticsGrid.unit3;
  
  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}