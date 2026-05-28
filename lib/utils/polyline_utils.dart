import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class PolylineUtils {
  /// Simplify Polyline (Douglas-Peucker Algorithm)
  /// Toleransi dalam derajat (contoh: 0.0001 ~ 11 meter)
  static List<LatLng> simplify(List<LatLng> points, {double tolerance = 0.0001}) {
    if (points.length <= 2) return points;

    double maxDistance = 0.0;
    int index = 0;

    for (int i = 1; i < points.length - 1; i++) {
      final double distance = _perpendicularDistance(points[i], points.first, points.last);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    if (maxDistance > tolerance) {
      final left = simplify(points.sublist(0, index + 1), tolerance: tolerance);
      final right = simplify(points.sublist(index), tolerance: tolerance);
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  /// Menghitung jarak tegak lurus (perpendicular distance) dalam derajat
  static double _perpendicularDistance(LatLng pt, LatLng lineStart, LatLng lineEnd) {
    double dx = lineEnd.longitude - lineStart.longitude;
    double dy = lineEnd.latitude - lineStart.latitude;

    // Jika lineStart dan lineEnd adalah titik yang sama
    if (dx == 0.0 && dy == 0.0) {
      final px = pt.longitude - lineStart.longitude;
      final py = pt.latitude - lineStart.latitude;
      return math.sqrt(px * px + py * py);
    }

    final double t = ((pt.longitude - lineStart.longitude) * dx +
            (pt.latitude - lineStart.latitude) * dy) /
        (dx * dx + dy * dy);

    if (t < 0) {
      dx = pt.longitude - lineStart.longitude;
      dy = pt.latitude - lineStart.latitude;
    } else if (t > 1) {
      dx = pt.longitude - lineEnd.longitude;
      dy = pt.latitude - lineEnd.latitude;
    } else {
      final closestX = lineStart.longitude + t * dx;
      final closestY = lineStart.latitude + t * dy;
      dx = pt.longitude - closestX;
      dy = pt.latitude - closestY;
    }

    return math.sqrt(dx * dx + dy * dy);
  }
}
