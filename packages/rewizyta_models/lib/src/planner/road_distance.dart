import 'dart:math';

/// A point in degrees.
typedef LatLng = ({double lat, double lng});

/// Roads are longer than the straight line between two stops; 1.3 is the usual
/// rule of thumb for rural Poland (docs/TRD.md, "Day planning").
const roadFactor = 1.3;

const _earthRadiusKm = 6371.0;

/// Estimated road distance in km: the haversine (great-circle) distance times
/// [roadFactor]. An estimate for ordering and fit, not a route.
double roadKm(LatLng from, LatLng to) {
  double radians(double degrees) => degrees * pi / 180;
  final dLat = radians(to.lat - from.lat);
  final dLng = radians(to.lng - from.lng);
  final h =
      pow(sin(dLat / 2), 2) + cos(radians(from.lat)) * cos(radians(to.lat)) * pow(sin(dLng / 2), 2);
  return 2 * _earthRadiusKm * asin(sqrt(h)) * roadFactor;
}
