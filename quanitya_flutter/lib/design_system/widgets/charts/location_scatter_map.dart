import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../primitives/quanitya_date_format.dart';
import 'package:latlong2/latlong.dart';

import '../../primitives/app_sizes.dart';
import '../../primitives/quanitya_palette.dart';

/// Data point for the location scatter map.
class LocationPoint {
  final DateTime date;
  final double latitude;
  final double longitude;

  const LocationPoint({
    required this.date,
    required this.latitude,
    required this.longitude,
  });
}

/// Location scatter map — plots location points on an OpenStreetMap tile layer,
/// colored by recency (older = faded, newer = strong).
///
/// Auto-fits bounds to contain all points with padding.
class LocationScatterMap extends StatelessWidget {
  final List<LocationPoint> data;
  final double height;
  final Color? dotColor;

  /// Optional accessibility summary for screen readers.
  final String? semanticSummary;

  const LocationScatterMap({
    super.key,
    required this.data,
    this.height = 250,
    this.dotColor,
    this.semanticSummary,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final color = dotColor ?? QuanityaPalette.category10[0];
    final sorted = List<LocationPoint>.of(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate time range for recency coloring
    final oldest = sorted.first.date.millisecondsSinceEpoch;
    final newest = sorted.last.date.millisecondsSinceEpoch;
    final timeSpan = newest - oldest;


    // Build markers with recency-based opacity
    final markers = sorted.map((point) {
      final t = timeSpan > 0
          ? (point.date.millisecondsSinceEpoch - oldest) / timeSpan
          : 1.0;
      final alpha = (0.2 + t * 0.8).clamp(0.2, 1.0);

      return Marker(
        point: LatLng(point.latitude, point.longitude),
        width: 14,
        height: 14,
        child: Tooltip(
          message: QuanityaDateFormat.full(point.date),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: alpha),
              shape: BoxShape.circle,
              border: Border.all(
                // True white for contrast against varied OSM map tile backgrounds.
                // backgroundPrimary (0xFFFAF7F0) is warm-tinted and would reduce
                // legibility across different tile color schemes.
                color: Colors.white.withValues(alpha: alpha * 0.8),
                width: 1.5,
              ),
            ),
          ),
        ),
      );
    }).toList();

    // Calculate bounds
    final bounds = LatLngBounds.fromPoints(
      sorted.map((p) => LatLng(p.latitude, p.longitude)).toList(),
    );

    final map = SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: sorted.length == 1
                ? LatLng(sorted.first.latitude, sorted.first.longitude)
                : bounds.center,
            initialZoom: sorted.length == 1 ? 14 : 2,
            initialCameraFit: sorted.length > 1
                ? CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(32),
                  )
                : null,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.qtpi.quanitya',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );

    final defaultLabel =
        'Location map: ${data.length} point${data.length == 1 ? '' : 's'}';
    return Semantics(
      label: semanticSummary ?? defaultLabel,
      child: ExcludeSemantics(child: map),
    );
  }
}
