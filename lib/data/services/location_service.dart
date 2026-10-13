import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_location.dart';

/// The phone's real position, with an honest fallback.
/// Ported from the `new-branch` work by BigzPh.
class LocationService {
  LocationService._();

  /// Fixed demo coordinate, used when location is off or refused. It is not
  /// a position ([GeoLocation.isLive] is false) and screens label it.
  static GeoLocation get demoLocation => GeoLocation(timestamp: DateTime.now());

  /// Whether the app may read the location. With [ask] false it never shows
  /// a permission dialog, so it is safe to call while an alert is counting.
  static Future<bool> hasPermission({bool ask = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && ask) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// A fresh GPS fix, else the last known position, else [demoLocation].
  static Future<GeoLocation> current({bool askPermission = false}) async {
    if (!await hasPermission(ask: askPermission)) return demoLocation;
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (e) {
      debugPrint('LocationService: no fresh fix ($e), trying last known');
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }
    if (position == null) return demoLocation;
    return GeoLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      altitudeMeters: position.altitude,
      timestamp: position.timestamp,
      isLive: true,
    );
  }

  /// Street, barangay, city, province for a coordinate, or null when offline
  /// or nothing is found.
  static Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final parts = <String>[];
      for (final part in [
        place.street,
        place.subLocality,
        place.locality ?? place.subAdministrativeArea,
        place.administrativeArea,
      ]) {
        final text = part?.trim() ?? '';
        if (text.isNotEmpty && !parts.contains(text)) parts.add(text);
      }
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
