import '../models/citizen_profile.dart';
import '../models/incident_models.dart';
import '../services/audio_evidence_service.dart';
import '../services/outbox_service.dart';
import '../services/supabase_service.dart';

class IncidentRepository {
  List<IncidentReport> _cachedReports = [];

  List<IncidentReport> get cachedReports => List.unmodifiable(_cachedReports);

  void clear() => _cachedReports = [];

  /// Reports sent from [phone]. Starts empty: no sample rows. Reports made on
  /// this phone that the server does not have yet (queued) stay in the list.
  Future<List<IncidentReport>> loadReports(String phone) async {
    final remote = await SupabaseService.fetchRecentReports(phone);
    if (remote.isNotEmpty) {
      final remoteIds = remote.map((r) => r.id).toSet();
      _cachedReports = [
        ..._cachedReports.where((r) => !remoteIds.contains(r.id)),
        ...remote,
      ];
    }
    return _cachedReports;
  }

  /// Starts recording the sound around the phone for the report. False when
  /// the microphone is not allowed; the report then carries a placeholder.
  Future<bool> startEvidence() => AudioEvidenceService.start();

  /// The alert was cancelled: the recording is deleted, nothing is uploaded.
  Future<void> cancelEvidence() => AudioEvidenceService.cancel();

  /// Uploads the recording made during the alert. When there is none, a
  /// generated placeholder tone is uploaded instead, because the reports
  /// table may require an audio URL (schema unknown). `recorded` says which,
  /// so screens can label it truthfully.
  Future<({String? url, bool recorded, int seconds})> uploadEvidence(
    String reportId,
  ) async {
    final recording = await AudioEvidenceService.stop();
    final bytes =
        recording ??
        AudioEvidenceService.generateEmergencyWavClip(durationSeconds: 5);
    String? url;
    try {
      url = await SupabaseService.uploadAudioEvidence(
        audioBytes: bytes,
        trackingCode: reportId,
      );
    } catch (_) {}
    return (
      url: url,
      // Only a recording that actually reached the server counts.
      recorded: recording != null && url != null,
      // Mono, 16-bit: two bytes per sample after the 44-byte header.
      seconds: recording == null
          ? 5
          : (AudioEvidenceService.wavDataBytes(bytes) /
                    (AudioEvidenceService.recordingSampleRate * 2))
                .round(),
    );
  }

  Future<bool> submitReport({
    required IncidentReport report,
    required CitizenProfile citizen,
  }) async {
    _cachedReports = [report, ..._cachedReports];
    return _send(report, citizen);
  }

  Future<bool> _send(IncidentReport report, CitizenProfile citizen) async {
    final verification = report.verificationResult;
    if (verification == null) return true;
    return SupabaseService.submitEmergencyReport(
      reportId: report.id,
      title: report.title,
      address: report.locationAddress,
      latitude: report.latitude,
      longitude: report.longitude,
      accuracy: report.accuracyMeters,
      status: report.status.displayName,
      isEmergency: report.isEmergency,
      verification: verification,
      citizen: citizen,
      audioEvidenceUrl: report.audioEvidenceUrl,
      occurredAt: report.timestamp,
    );
  }

  Future<void> queueForRetry(IncidentReport report, CitizenProfile citizen) =>
      OutboxService.add({
        'report': report.toJson(),
        'citizen': citizen.toJson(),
      });

  /// Returns how many queued reports were delivered.
  Future<int> flushOutbox({bool force = false}) => OutboxService.flush(
        (e) => _send(
          IncidentReport.fromJson(e['report'] as Map<String, dynamic>),
          CitizenProfile.fromJson(e['citizen'] as Map<String, dynamic>),
        ),
        force: force,
      );
}
