enum PolicyAction {
  suppress,
  verify,
  escalate,
}

enum IncidentStatus {
  detected('Detected'),
  pendingCancel('Pending Verification'),
  submitted('Submitted'),
  received('Received'),
  acknowledged('Acknowledged'),
  assigned('Assigned'),
  responding('Responding (In Progress)'),
  resolved('Resolved'),
  canceled('Canceled'),
  falseAlarm('Suppressed / False Alarm');

  final String displayName;
  const IncidentStatus(this.displayName);
}

class GuardrailResult {
  final String transcript;
  final String detectedKeyword;
  final String riskLevel; // 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  final double? confidence;
  final String reasons;
  final PolicyAction recommendedPolicy;
  final String category;
  final bool isEmergency;

  const GuardrailResult({
    required this.transcript,
    required this.detectedKeyword,
    required this.riskLevel,
    this.confidence,
    required this.reasons,
    required this.recommendedPolicy,
    this.category = 'general_distress',
    this.isEmergency = false,
  });

  Map<String, dynamic> toJson() => {
        'transcript': transcript,
        'detected_keyword': detectedKeyword,
        'risk_level': riskLevel,
        'confidence': confidence,
        'reasons': reasons,
        'recommended_policy': recommendedPolicy.name.toUpperCase(),
        'category': category,
        'is_emergency': isEmergency,
      };

  factory GuardrailResult.fromJson(Map<String, dynamic> json) =>
      GuardrailResult(
        transcript: json['transcript'] as String? ?? '',
        detectedKeyword: json['detected_keyword'] as String? ?? 'None',
        riskLevel: json['risk_level'] as String? ?? 'MEDIUM',
        confidence: (json['confidence'] as num?)?.toDouble(),
        reasons: json['reasons'] as String? ?? '',
        recommendedPolicy: switch (json['recommended_policy']) {
          'SUPPRESS' => PolicyAction.suppress,
          'ESCALATE' => PolicyAction.escalate,
          _ => PolicyAction.verify,
        },
        category: json['category'] as String? ?? 'general_distress',
        isEmergency: json['is_emergency'] as bool? ?? false,
      );
}

class IncidentReport {
  final String id;
  final String title;
  final DateTime timestamp;
  final IncidentStatus status;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String triggerSource;
  final int audioDurationSec;
  final String? transcript;
  final GuardrailResult? verificationResult;
  final bool isEmergency;
  final bool isSimulated;
  final String? audioEvidenceUrl;

  /// Whether the attached audio is a real recording (true) or the generated
  /// placeholder tone (false). Known only for reports made on this phone;
  /// null for reports read back from the server, which does not store it.
  final bool? audioRecorded;

  /// True when the coordinates are the fixed demo point, not a GPS fix.
  bool get hasDemoLocation => latitude == 14.1883 && longitude == 121.1652;

  const IncidentReport({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.status,
    this.locationAddress = 'Block 3, Sitio Buntog, Calamba, Laguna',
    this.latitude = 14.1883,
    this.longitude = 121.1652,
    this.accuracyMeters = 4.2,
    this.triggerSource = 'Manual SOS',
    this.audioDurationSec = 5,
    this.transcript,
    this.verificationResult,
    this.isEmergency = true,
    this.isSimulated = true,
    this.audioEvidenceUrl,
    this.audioRecorded,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'timestamp': timestamp.toIso8601String(),
        'status': status.displayName,
        'location_address': locationAddress,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_meters': accuracyMeters,
        'trigger_source': triggerSource,
        'audio_duration_sec': audioDurationSec,
        'transcript': transcript,
        'verification_result': verificationResult?.toJson(),
        'is_emergency': isEmergency,
        'is_simulated': isSimulated,
        'audio_evidence_url': audioEvidenceUrl,
        'audio_recorded': audioRecorded,
      };

  factory IncidentReport.fromJson(Map<String, dynamic> json) => IncidentReport(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Emergency Incident',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        status: IncidentStatus.values.firstWhere(
          (s) => s.displayName == json['status'],
          orElse: () => IncidentStatus.submitted,
        ),
        locationAddress: json['location_address'] as String? ??
            'Block 3, Sitio Buntog, Calamba, Laguna',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 14.1883,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 121.1652,
        accuracyMeters:
            (json['accuracy_meters'] as num?)?.toDouble() ?? 4.2,
        triggerSource: json['trigger_source'] as String? ?? 'Manual SOS',
        audioDurationSec: json['audio_duration_sec'] as int? ?? 5,
        transcript: json['transcript'] as String?,
        verificationResult: json['verification_result'] != null
            ? GuardrailResult.fromJson(
                json['verification_result'] as Map<String, dynamic>)
            : null,
        isEmergency: json['is_emergency'] as bool? ?? true,
        isSimulated: json['is_simulated'] as bool? ?? true,
        audioEvidenceUrl: json['audio_evidence_url'] as String?,
        audioRecorded: json['audio_recorded'] as bool?,
      );
}

enum ReportFilter {
  all('All'),
  emergency('Emergency'),
  safetyCheck('Safety Check');

  final String label;
  const ReportFilter(this.label);
}
