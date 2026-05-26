import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static const LatLng defaultCenter = LatLng(-7.7956, 110.3695);

  static final LocationService instance = LocationService._();

  Future<Position?> getCurrentPosition() async {
    // Ensure service enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) return null;

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

Stream<Position> getPositionStream() {
    // Callers can handle permission/messages before using stream.
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  static LatLng positionToLatLng(Position p) => LatLng(p.latitude, p.longitude);
}
