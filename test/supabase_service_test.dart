import 'package:flutter_test/flutter_test.dart';
import 'package:dinig/data/services/audio_evidence_service.dart';
import 'package:dinig/data/services/supabase_service.dart';
import 'package:dinig/data/models/citizen_profile.dart';
import 'package:dinig/data/models/incident_models.dart';

void main() {
  test('SupabaseService sends emergency report and audio evidence to Supabase successfully', () async {
    final uniqueSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
    final testReportId = 'DNG-2026-TEST$uniqueSuffix';

    // 1. Generate & Upload 5-second acoustic WAV clip
    final audioBytes = AudioEvidenceService.generateEmergencyWavClip(durationSeconds: 5);
    expect(audioBytes.length, greaterThan(44)); // Valid RIFF header + PCM data

    final audioUrl = await SupabaseService.uploadAudioEvidence(
      audioBytes: audioBytes,
      trackingCode: testReportId,
    );
    expect(audioUrl, isNotNull);
    expect(audioUrl, contains('audio-evidence/distress_$testReportId.wav'));

    const verification = GuardrailResult(
      transcript: 'Tulong po may nasusunog sa Sitio Buntog!',
      detectedKeyword: 'Tulong',
      riskLevel: 'CRITICAL',
      confidence: 0.99,
      reasons: 'Emergency fire verification test with audio evidence',
      recommendedPolicy: PolicyAction.escalate,
      category: 'fire_emergency',
      isEmergency: true,
    );

    const citizen = CitizenProfile(
      fullName: 'Maria Santos',
      phoneNumber: '+63 917 123 4567',
      barangay: 'Brgy. Canlubang',
      city: 'Calamba',
      province: 'Laguna',
    );

    // 2. Submit emergency report with uploaded audio evidence URL
    final success = await SupabaseService.submitEmergencyReport(
      reportId: testReportId,
      title: 'Voice Alert (Tulong)',
      address: 'Sitio Buntog, Calamba, Laguna',
      latitude: 14.2112,
      longitude: 121.0543,
      accuracy: 4.2,
      status: 'Submitted',
      isEmergency: true,
      verification: verification,
      citizen: citizen,
      audioEvidenceUrl: audioUrl,
    );

    expect(success, isTrue);

    // 3. Verify report is retrievable from Supabase with audio evidence attached
    final reports = await SupabaseService.fetchRecentReports(citizen.phoneNumber);
    expect(reports.isNotEmpty, isTrue);
    final report = reports.firstWhere((r) => r.id == testReportId);
    expect(report.audioEvidenceUrl, isNotNull);
    expect(report.audioEvidenceUrl, contains('distress_$testReportId.wav'));
  });
}

