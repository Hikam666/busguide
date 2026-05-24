import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmRouteData {
  final List<LatLng> polyline;
  final double distanceMeters;
  final double durationSeconds;

  OsrmRouteData({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class OsrmService {
  static const String baseUrl = 'http://router.project-osrm.org/route/v1/driving';

  Future<OsrmRouteData?> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;

    // OSRM format: lon,lat;lon,lat
    final coordinates = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final url = Uri.parse('$baseUrl/$coordinates?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          // Parse GeoJSON coordinates
          final geometry = route['geometry']['coordinates'] as List;
          final polyline = geometry.map((coord) {
            // GeoJSON returns [lon, lat]
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();

          return OsrmRouteData(
            polyline: polyline,
            distanceMeters: (route['distance'] as num).toDouble(),
            durationSeconds: (route['duration'] as num).toDouble(),
          );
        }
      }
    } catch (e) {
      print('OSRM Error: $e');
    }
    return null;
  }
}
