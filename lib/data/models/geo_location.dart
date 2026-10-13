class GeoLocation {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double? altitudeMeters;
  final DateTime timestamp;

  /// True when this came from the phone's location hardware. False for the
  /// fixed demo coordinate used when location is off or refused.
  final bool isLive;

  const GeoLocation({
    this.latitude = 14.1883,
    this.longitude = 121.1652,
    this.accuracyMeters = 4.2,
    this.altitudeMeters,
    required this.timestamp,
    this.isLive = false,
  });

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';

  String get formattedAccuracy => '±${accuracyMeters.toStringAsFixed(1)}m';

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_meters': accuracyMeters,
        'altitude_meters': altitudeMeters,
        'timestamp': timestamp.toIso8601String(),
      };
}
