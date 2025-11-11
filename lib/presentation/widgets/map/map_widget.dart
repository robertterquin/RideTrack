import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Reusable OpenStreetMap Widget
/// Displays an interactive map with customizable center, zoom, and markers
class MapWidget extends StatelessWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<Marker>? markers;
  final List<Polyline>? polylines;
  final MapController? mapController;
  final Function(LatLng)? onTap;

  const MapWidget({
    super.key,
    required this.initialCenter,
    this.initialZoom = 12.0,
    this.markers,
    this.polylines,
    this.mapController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        onTap: onTap != null ? (tapPosition, point) => onTap!(point) : null,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.bikeapp',
        ),
        if (markers != null && markers!.isNotEmpty)
          MarkerLayer(markers: markers!),
        if (polylines != null && polylines!.isNotEmpty)
          PolylineLayer(polylines: polylines!),
      ],
    );
  }
}
