import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/citizen_profile.dart';
import '../models/incident_models.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://meeqjdspladepbqecczd.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1lZXFqZHNwbGFkZXBicWVjY3pkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NTQ5OTcsImV4cCI6MjEwNzEzMDk5N30.B2H12f1iay5RBynVcdFAG1zwvQvdz_Lids0-NipH2xs';

  // Without this a dead connection hangs the dispatch for the OS default (~60s).
  static const Duration _timeout = Duration(seconds: 10);

  static Map<String, String> get _headers => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  /// Normalizes trigger word to allowed enum values ('tulong', 'help') or null
  static String? _normalizeTriggerWord(String? word) {
    if (word == null) return null;
    final w = word.toLowerCase().trim();
    if (w.contains('tulong') || w.contains('saklolo')) return 'tulong';
    if (w.contains('help')) return 'help';
    return null;
  }

  /// Normalizes trigger source to 'voice_trigger', 'manual_sos', or 'citizen_call'
  static String _normalizeTriggerSource(String? source, String? keyword) {
    final s = (source ?? '').toLowerCase();
    final k = (keyword ?? '').toLowerCase();
    if (s.contains('manual') || k.contains('manual')) return 'manual_sos';
    if (s.contains('call') || k.contains('call')) return 'citizen_call';
    return 'voice_trigger';
  }

  /// Normalizes category to allowed check constraint values
  static String _normalizeCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('fire')) return 'fire_hazard';
    if (c.contains('med') || c.contains('health')) return 'medical';
    if (c.contains('harass') || c.contains('threat')) return 'harassment';
    if (c.contains('accident') || c.contains('crash')) return 'accident';
    if (c.contains('joke') ||
        c.contains('game') ||
        c.contains('chore') ||
        c.contains('study') ||
        c.contains('suppress') ||
        c.contains('false')) {
      return 'false_positive_filtered';
    }
    if (c.contains('suspicious') || c.contains('ambiguous')) return 'suspicious';
    return 'physical_danger';
  }

  /// Normalizes AI classification to 'high_risk', 'uncertain', or 'low_risk'
  static String _normalizeAiClassification(String riskLevel, bool isEmergency) {
    if (!isEmergency) return 'low_risk';
    final r = riskLevel.toUpperCase();
    if (r == 'CRITICAL' || r == 'HIGH') return 'high_risk';
    if (r == 'MEDIUM') return 'uncertain';
    return 'low_risk';
  }

  /// Normalizes recommended action to allowed check constraint values
  static String _normalizeRecommendedAction(PolicyAction policy) {
    return switch (policy) {
      PolicyAction.escalate => 'urgent_escalation',
      PolicyAction.verify => 'rapid_verification',
      PolicyAction.suppress => 'no_automatic_report',
    };
  }

  /// Normalizes priority to P1_CRITICAL, P2_HIGH, P3_MEDIUM, or P4_LOW
  static String _normalizePriority(String riskLevel) {
    return switch (riskLevel.toUpperCase()) {
      'CRITICAL' => 'P1_CRITICAL',
      'HIGH' => 'P2_HIGH',
      'MEDIUM' => 'P3_MEDIUM',
      _ => 'P4_LOW',
    };
  }

  /// Normalizes status to allowed check constraint values
  static String _normalizeStatus(String status) {
    final s = status.toUpperCase().replaceAll(RegExp(r'\s+'), '_');
    if (s.contains('DETECTED')) return 'DETECTED';
    if (s.contains('PENDING')) return 'PENDING_CANCEL';
    if (s.contains('SUBMITTED')) return 'SUBMITTED';
    if (s.contains('RECEIVED')) return 'RECEIVED';
    if (s.contains('ACKNOWLEDGED')) return 'ACKNOWLEDGED';
    if (s.contains('ASSIGNED')) return 'ASSIGNED';
    if (s.contains('RESPONDING')) return 'RESPONDING';
    if (s.contains('RESOLVED')) return 'RESOLVED';
    if (s.contains('FALSE') || s.contains('SUPPRESSED')) return 'FALSE_ALARM';
    if (s.contains('CANCEL')) return 'CANCELED';
    return 'RECEIVED';
  }

  /// Submits an emergency incident report to Supabase public.emergency_reports
  ///
  /// Column and enum names here (`ai_classification`, `ai_confidence`,
  /// `voice_trigger`, `audio_evidence_url`) belong to the existing table, whose
  /// schema is unknown, so they are kept as they are. They are not claims: the
  /// classification comes from a rule-based matcher, the confidence is a fixed
  /// placeholder, and the audio is a generated tone. Every row is sent with
  /// `is_simulated: true`. The non-null fallbacks below exist only because a
  /// column may be NOT NULL.
  static Future<bool> submitEmergencyReport({
    required String reportId,
    required String title,
    required String address,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String status,
    required bool isEmergency,
    required GuardrailResult verification,
    required CitizenProfile citizen,
    String? audioEvidenceUrl,
    DateTime? occurredAt,
  }) async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      // Derived from the incident time, not the send time, so a retry reuses
      // the same id instead of creating a duplicate row.
      final at = (occurredAt ?? DateTime.now()).toUtc();
      final incidentId = reportId.toLowerCase().startsWith('inc-')
          ? reportId
          : 'inc-${at.millisecondsSinceEpoch}';

      final triggerWord = _normalizeTriggerWord(verification.detectedKeyword);
      final triggerSource =
          _normalizeTriggerSource(title, verification.detectedKeyword);
      final aiClassification =
          _normalizeAiClassification(verification.riskLevel, isEmergency);
      final recommendedAction =
          _normalizeRecommendedAction(verification.recommendedPolicy);
      final category = _normalizeCategory(verification.category);
      final priority = _normalizePriority(verification.riskLevel);
      final normalizedStatus = _normalizeStatus(status);

      final payload = {
        'id': incidentId,
        'tracking_code': reportId,
        'trigger_source': triggerSource,
        'trigger_word': triggerWord,
        'transcript': verification.transcript.isNotEmpty
            ? verification.transcript
            : null,
        'ai_classification': aiClassification,
        'ai_confidence': verification.confidence ?? (isEmergency ? 0.985 : 0.85),
        'ai_reason': verification.reasons.isNotEmpty
            ? verification.reasons
            : 'No reason recorded',
        'recommended_action': recommendedAction,
        'category': category,
        'priority': priority,
        'status': normalizedStatus,
        'occurred_at': at.toIso8601String(),
        'received_at': nowIso,
        'barangay': citizen.barangay.isNotEmpty ? citizen.barangay : 'Brgy. Canlubang',
        'city': citizen.city.isNotEmpty ? citizen.city : 'Calamba',
        'location_address':
            address.isNotEmpty ? address : 'Block 3, Sitio Buntog, Calamba, Laguna',
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_m': accuracy > 0 ? accuracy : 4.2,
        'citizen_name':
            citizen.fullName.isNotEmpty ? citizen.fullName : 'Citizen',
        'citizen_phone': citizen.phoneNumber.isNotEmpty
            ? citizen.phoneNumber
            : '+63 917 842 1928',
        'audio_evidence_url': audioEvidenceUrl ??
            'https://meeqjdspladepbqecczd.supabase.co/storage/v1/object/public/audio-evidence/distress_sample.wav',
        'is_simulated': true,
        'display_type': title.isNotEmpty ? title : 'Emergency report',
        'display_status': 'Emergency',
        // Placeholder text: nothing in this app assigns responders.
        'responders_summary': 'Barangay Tanod, PNP Calamba',
      };

      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/emergency_reports'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(_timeout);

      // 409 = this id already exists, i.e. an earlier attempt was delivered.
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 409) {
        debugPrint(
            '✅ Supabase incident report dispatched: $reportId (HTTP ${response.statusCode})');
        return true;
      } else {
        debugPrint(
            '❌ Supabase submitEmergencyReport failed: HTTP ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stack) {
      debugPrint('❌ Supabase submitEmergencyReport exception: $e\n$stack');
      return false;
    }
  }

  /// Uploads audio bytes (16kHz mono WAV) to Supabase Storage 'audio-evidence' bucket.
  /// Returns the public accessible URL on success.
  static Future<String?> uploadAudioEvidence({
    required Uint8List audioBytes,
    required String trackingCode,
    String mimeType = 'audio/wav',
  }) async {
    try {
      final fileName = 'distress_$trackingCode.wav';
      final response = await http.post(
        Uri.parse('$supabaseUrl/storage/v1/object/audio-evidence/$fileName'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': mimeType,
          'x-upsert': 'true',
        },
        body: audioBytes,
      ).timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final publicUrl =
            '$supabaseUrl/storage/v1/object/public/audio-evidence/$fileName';
        debugPrint('✅ Audio evidence uploaded to Supabase Storage: $publicUrl');
        return publicUrl;
      } else {
        debugPrint(
            '❌ Supabase audio upload failed: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('❌ Supabase audio upload exception: $e\n$stack');
    }
    return null;
  }

  /// Fetches this phone number's recent reports, never other residents'.
  static Future<List<IncidentReport>> fetchRecentReports(String phone) async {
    if (phone.trim().isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse(
            '$supabaseUrl/rest/v1/emergency_reports?select=*&citizen_phone=eq.${Uri.encodeQueryComponent(phone)}&order=received_at.desc&limit=20'),
        headers: _headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final rawAction =
              m['recommended_action'] as String? ?? 'rapid_verification';
          final policy = switch (rawAction) {
            'no_automatic_report' => PolicyAction.suppress,
            'urgent_escalation' => PolicyAction.escalate,
            _ => PolicyAction.verify,
          };
          final trackingCode = m['tracking_code'] as String? ??
              m['id'] as String? ??
              'DNG-TEMP';
          final rawStatus =
              (m['status'] as String? ?? 'RECEIVED').toUpperCase();
          final status = switch (rawStatus) {
            'DETECTED' => IncidentStatus.detected,
            'PENDING_CANCEL' => IncidentStatus.pendingCancel,
            'SUBMITTED' => IncidentStatus.submitted,
            'RECEIVED' => IncidentStatus.received,
            'ACKNOWLEDGED' => IncidentStatus.acknowledged,
            'ASSIGNED' => IncidentStatus.assigned,
            'RESPONDING' => IncidentStatus.responding,
            'RESOLVED' => IncidentStatus.resolved,
            'CANCELED' => IncidentStatus.canceled,
            'FALSE_ALARM' => IncidentStatus.falseAlarm,
            _ => IncidentStatus.received,
          };
          final triggerWord = m['trigger_word'] as String?;
          final triggerSource =
              m['trigger_source'] as String? ?? 'voice_trigger';
          final displayType = m['display_type'] as String? ??
              'Emergency report';
          final isHighRisk = m['ai_classification'] == 'high_risk';

          return IncidentReport(
            id: trackingCode,
            title: displayType,
            timestamp: DateTime.tryParse(m['received_at'] as String? ?? '') ??
                DateTime.tryParse(m['occurred_at'] as String? ?? '') ??
                DateTime.now(),
            status: status,
            locationAddress: m['location_address'] as String? ??
                'Block 3, Sitio Buntog, Calamba, Laguna',
            latitude: (m['latitude'] as num?)?.toDouble() ?? 14.1883,
            longitude: (m['longitude'] as num?)?.toDouble() ?? 121.1652,
            accuracyMeters: (m['accuracy_m'] as num?)?.toDouble() ?? 4.2,
            triggerSource:
                triggerSource == 'manual_sos' ? 'Manual SOS' : 'Phrase check',
            audioDurationSec: 5,
            transcript: m['transcript'] as String?,
            verificationResult: GuardrailResult(
              transcript: m['transcript'] as String? ?? '',
              detectedKeyword: triggerWord ??
                  (triggerSource == 'manual_sos' ? 'Manual SOS' : 'None'),
              riskLevel: switch (m['ai_classification'] as String? ?? '') {
                'high_risk' => 'CRITICAL',
                'uncertain' => 'MEDIUM',
                _ => 'LOW',
              },
              confidence: (m['ai_confidence'] as num?)?.toDouble() ?? 0.95,
              reasons: m['ai_reason'] as String? ?? 'Verified trigger',
              recommendedPolicy: policy,
              category: m['category'] as String? ?? 'physical_danger',
              isEmergency: isHighRisk,
            ),
            isEmergency: isHighRisk,
            isSimulated: m['is_simulated'] as bool? ?? true,
            audioEvidenceUrl: m['audio_evidence_url'] as String?,
          );
        }).toList();
      } else {
        debugPrint(
            '❌ Supabase fetchRecentReports error: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('❌ Supabase fetchRecentReports exception: $e\n$stack');
    }
    return [];
  }

  /// Registers resident citizen in Supabase public.residents table
  static Future<bool> registerResident(CitizenProfile profile) async {
    try {
      final names = profile.fullName.trim().split(RegExp(r'\s+'));
      final firstName = names.isNotEmpty ? names.first : 'Citizen';
      final lastName =
          names.length > 1 ? names.sublist(1).join(' ') : 'Resident';

      final payload = {
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': profile.phoneNumber,
        'email': profile.email.isNotEmpty ? profile.email : null,
        'barangay': profile.barangay,
        'address': '${profile.barangay}, ${profile.city}',
        'emergency_contact_name': profile.emergencyContactName,
        'emergency_contact_phone': profile.emergencyContactPhone,
        'medical_conditions': [
          if (profile.medicalNotes.isNotEmpty) profile.medicalNotes,
          if (profile.supportNotes.isNotEmpty)
            'Support notes: ${profile.supportNotes}',
        ].join(' | '),
        'auth_user_id': profile.authUserId,
        'status': 'REGISTERED',
      };

      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/residents'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint(
            '✅ Supabase resident profile registered: ${profile.fullName}');
        return true;
      } else {
        debugPrint(
            '❌ Supabase registerResident error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stack) {
      debugPrint('❌ Supabase registerResident exception: $e\n$stack');
      return false;
    }
  }
}

