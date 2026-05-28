import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteData {
  final List<LatLng> polyline;
  final double distanceMeters;
  final double durationSeconds;

  RouteData({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class OsrmRoutesService {
  static const String _baseUrl = 'http://router.project-osrm.org/route/v1/driving/';

  /// Ambil rute dari OSRM API (Gratis, tanpa API Key)
  Future<RouteData?> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;

    // OSRM menggunakan format: Lng,Lat;Lng,Lat
    final coordinates = waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');

    final url = Uri.parse('$_baseUrl$coordinates?overview=full&geometries=polyline');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final encodedPolyline = route['geometry'] as String;
          final polyline = _decodePolyline(encodedPolyline);

          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSeconds = (route['duration'] as num).toDouble();

          return RouteData(
            polyline: polyline,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
          );
        }
      } else {
         debugPrint('OSRM API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('OSRM Routes Error: $e');
    }
    return null;
  }

  // Decode OSRM encoded polyline (v5) menjadi daftar koordinat LatLng
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
