import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Ray-casting point-in-polygon test.
/// Returns true if [point] is inside [polygon].
/// If the polygon has fewer than 3 points (not drawn yet), treats
/// everything as "safe" so no false alerts fire before a zone exists.
bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
  if (polygon.length < 3) return true;

  bool inside = false;
  int j = polygon.length - 1;
  for (int i = 0; i < polygon.length; i++) {
    final xi = polygon[i].longitude, yi = polygon[i].latitude;
    final xj = polygon[j].longitude, yj = polygon[j].latitude;

    final intersects = ((yi > point.latitude) != (yj > point.latitude)) &&
        (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);

    if (intersects) inside = !inside;
    j = i;
  }
  return inside;
}

/// Shortest distance in meters from [point] to the polygon's boundary.
/// Uses a flat (equirectangular) projection centered on each edge, which
/// is accurate enough for neighborhood-sized safe zones (a few km across).
double distanceToPolygonBoundaryMeters(LatLng point, List<LatLng> polygon) {
  if (polygon.length < 2) return double.infinity;

  double minDist = double.infinity;
  for (int i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    final d = _distanceToSegmentMeters(point, a, b);
    if (d < minDist) minDist = d;
  }
  return minDist;
}

double _distanceToSegmentMeters(LatLng p, LatLng a, LatLng b) {
  const metersPerDegLat = 111320.0;
  final refLatRad = (a.latitude + b.latitude) / 2 * (pi / 180);
  final metersPerDegLng = 111320.0 * cos(refLatRad);

  // Project a, b, p into a local flat meters plane with a at the origin.
  final bx = (b.longitude - a.longitude) * metersPerDegLng;
  final by = (b.latitude - a.latitude) * metersPerDegLat;
  final px = (p.longitude - a.longitude) * metersPerDegLng;
  final py = (p.latitude - a.latitude) * metersPerDegLat;

  final abLen2 = bx * bx + by * by;
  double t = abLen2 == 0 ? 0 : ((px * bx + py * by) / abLen2);
  t = t.clamp(0.0, 1.0);

  final closestX = t * bx;
  final closestY = t * by;
  final dx = px - closestX;
  final dy = py - closestY;
  return sqrt(dx * dx + dy * dy);
}