import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/citizen_profile.dart';
import '../../data/models/geo_location.dart';
import '../../data/models/incident_models.dart';
import '../../data/repositories/incident_repository.dart';
import '../../data/services/audio_evidence_service.dart';
import '../../data/services/listening_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/phrase_guardrail.dart';
import '../../data/services/outbox_service.dart';
import '../../data/services/preferences_service.dart';

/// What the citizen is told about delivery of the active alert.
enum DispatchState { idle, sending, sent, queued }

/// Picture-button needs for Care Mode (no typing or speaking required).
/// [hurt], [fire] and [lost] report to the barangay after a countdown.
/// [scared] and [grownUp] only call the caregiver: no countdown, no report.
enum CareNeed {
  hurt('Hurt', 'I am hurt', 'medical_emergency', 'CRITICAL'),
  fire('Fire', 'There is a fire', 'fire_emergency', 'CRITICAL'),
  lost('Lost', 'I am lost', 'physical_danger', 'HIGH'),
  scared('Scared', 'I am scared'),
  grownUp('Need a grown-up', 'I need a grown-up');

  final String label;
  final String phrase;
  final String? category;
  final String? riskLevel;
  const CareNeed(this.label, this.phrase, [this.category, this.riskLevel]);

  bool get callsCaregiver => category == null;
}

class DinigViewModel extends ChangeNotifier {
  static const int escalateSeconds = 5;
  static const int verifySeconds = 10;

  final IncidentRepository _repository;
  final DateTime Function() _now;
  final ListeningService _listener;
  final Future<void> Function(String title, String body) _notify;

  bool _listeningOn = false;
  bool get listeningOn => _listeningOn;

  /// Why listening could not start, in plain words; null when there is no problem.
  String? _listeningProblem;
  String? get listeningProblem => _listeningProblem;

  /// The last phrase with a trigger word that was heard, and what was decided.
  String? _lastHeard;
  String? get lastHeard => _lastHeard;

  /// Set by the app shell: shows the countdown screen for a voice alert.
  VoidCallback? onVoiceAlert;

  GuardrailResult? _activeVerificationResult;
  GuardrailResult? get activeVerificationResult => _activeVerificationResult;

  GuardrailResult? _suppressionDialogResult;
  GuardrailResult? get suppressionDialogResult => _suppressionDialogResult;

  int _countdownSecondsRemaining = verifySeconds;
  int get countdownSecondsRemaining => _countdownSecondsRemaining;

  IncidentReport? _activeIncident;
  IncidentReport? get activeIncident => _activeIncident;

  ReportFilter _reportFilter = ReportFilter.emergency;
  ReportFilter get reportFilter => _reportFilter;

  CitizenProfile _userProfile = const CitizenProfile();
  CitizenProfile get userProfile => _userProfile;

  /// The phone's position when location is allowed ([GeoLocation.isLive]);
  /// otherwise the fixed demo coordinate, which screens must label as such.
  GeoLocation _currentLocation = LocationService.demoLocation;
  GeoLocation get currentLocation => _currentLocation;

  /// Street-level address for [currentLocation], when it could be looked up.
  String? _resolvedAddress;
  String? get resolvedAddress => _resolvedAddress;

  /// Whether a report can carry a real recording instead of a placeholder.
  bool _recordingAllowed = false;
  bool get recordingAllowed => _recordingAllowed;

  /// True while the sound around the phone is being recorded for an alert.
  bool _recordingEvidence = false;
  bool get recordingEvidence => _recordingEvidence;

  /// True when the active alert was started by a heard phrase.
  bool get alertFromVoice => _triggerLabel.startsWith('Voice');

  List<IncidentReport> get reports => _repository.cachedReports;

  Timer? _countdownTimer;
  DateTime? _deadline;

  /// How the active alert was started, in the citizen's own words.
  String _triggerLabel = 'Manual SOS';

  DispatchState _dispatchState = DispatchState.idle;
  DispatchState get dispatchState => _dispatchState;

  int _pendingReports = 0;
  int get pendingReports => _pendingReports;
  Timer? _outboxTimer;

  /// Completes once persisted state is loaded (never throws), so the shell
  /// can pick the first screen from the stored profile.
  late final Future<void> ready;

  DinigViewModel({
    IncidentRepository? repository,
    DateTime Function()? now,
    ListeningService? listener,
    Future<void> Function(String title, String body)? notify,
  }) : _repository = repository ?? IncidentRepository(),
       _now = now ?? DateTime.now,
       _listener = listener ?? ListeningService(),
       _notify = notify ?? NotificationService.show {
    _listener.onPhrase = heardPhrase;
    _listener.onEngineState = (responding) {
      _listeningProblem = responding
          ? null
          : 'Speech recognition is not answering, so nothing can be heard '
                'right now. iOS refuses it while DINIG is in the background. '
                'Otherwise check the microphone (a Bluetooth headset can '
                'give no sound), that Dictation is on, and that the phone '
                'is online.';
      if (!responding) {
        // Shown only when the app is not on screen, which is when iOS
        // refuses speech recognition: never leave the person thinking the
        // phone is still listening.
        _notify(
          'DINIG is not listening',
          'iOS stopped speech recognition in the background. Open DINIG to listen again.',
        );
      }
      notifyListeners();
    };
    ready = _init();
  }

  Future<void> _init() async {
    try {
      _userProfile = await PreferencesService.getProfile();
      _pendingReports = await OutboxService.pendingCount();
    } catch (e) {
      debugPrint('DinigViewModel init error: $e');
    }
    notifyListeners();
    if (_pendingReports > 0) {
      _ensureOutboxTimer();
      retryPending();
    }
    // Network is not on the boot path: reports fill in whenever they arrive.
    _loadReports();
    // Listening was left on last time: pick it up again.
    if (await PreferencesService.isListeningOn()) setListening(true);
    // Neither call shows a permission dialog, and neither is awaited: the
    // first screen must never wait on a plugin.
    AudioEvidenceService.hasPermission().then((allowed) {
      _recordingAllowed = allowed;
      notifyListeners();
    });
    refreshLocation();
  }

  /// Whether iOS lets DINIG read the position. A phone can allow it and
  /// still have no position yet (indoors, or a simulator with none set).
  bool _locationAllowed = false;
  bool get locationAllowed => _locationAllowed;

  /// The position read in flight, so a report can wait for it.
  Future<void>? _locating;

  Future<void> _locate(bool ask) async {
    final location = await LocationService.current(askPermission: ask);
    // A read that failed must not replace a real position with the demo one.
    if (location.isLive || !_currentLocation.isLive) {
      _currentLocation = location;
    }
  }

  /// Reads the phone's position. Only with [ask] true may it show the
  /// permission dialog; alerts call it without, so nothing covers Cancel.
  Future<void> refreshLocation({bool ask = false}) async {
    await (_locating = _locate(ask));
    _locationAllowed = await LocationService.hasPermission();
    final location = _currentLocation;
    _resolvedAddress = location.isLive
        ? await LocationService.reverseGeocode(
            location.latitude,
            location.longitude,
          )
        : null;
    notifyListeners();
  }

  /// Asks for location and microphone access, from a button on Home.
  Future<void> requestPermissions() async {
    await refreshLocation(ask: true);
    _recordingAllowed = await AudioEvidenceService.hasPermission(ask: true);
    notifyListeners();
  }

  /// Turns continuous listening on or off. Turning it on asks for the
  /// microphone, speech recognition and notification permissions.
  Future<void> setListening(bool on) async {
    if (on) {
      await NotificationService.init();
      _listeningOn = await _listener.start();
      _listeningProblem = _listeningOn
          ? null
          : 'Listening could not start. Allow Microphone and Speech '
                'Recognition for DINIG in Settings.';
    } else {
      await _listener.stop();
      _listeningOn = false;
      _listeningProblem = null;
    }
    await PreferencesService.setListeningOn(_listeningOn);
    notifyListeners();
  }

  bool get _alertActive =>
      (_countdownTimer?.isActive ?? false) ||
      _dispatchState == DispatchState.sending;

  /// A phrase containing a trigger word, heard by the speech engine. It goes
  /// through the same rules as a typed phrase. A "no alert" result only
  /// updates [lastHeard]: a dialog for every joke in the room would be noise.
  void heardPhrase(String phrase) {
    if (_alertActive) return;
    final result = PhraseGuardrail.analyze(phrase);
    if (result.recommendedPolicy == PolicyAction.suppress) {
      _lastHeard = '"${result.transcript}": no alert. ${result.reasons}';
      notifyListeners();
      return;
    }
    final seconds = result.recommendedPolicy == PolicyAction.escalate
        ? escalateSeconds
        : verifySeconds;
    _lastHeard = '"${result.transcript}": alert started.';
    // Same countdown as a typed phrase: it sends unless someone cancels.
    _beginAlert(
      result,
      label: 'Voice trigger ("${result.detectedKeyword}")',
      seconds: seconds,
      onNavigateToEmergency: onVoiceAlert ?? () {},
    );
    _notify(
      'DINIG heard "${result.detectedKeyword}"',
      'Sending a report in $seconds seconds. Open DINIG to cancel.',
    );
  }

  /// iOS may stop the microphone while the app is in the background; pick
  /// listening up again when the app comes back to the front.
  void appResumed() {
    if (_listeningOn) _listener.start();
  }

  /// The app came back to the front: the phone may have moved.
  void appForegrounded() {
    appResumed();
    refreshLocation();
  }

  void _loadReports() => _repository
      .loadReports(_userProfile.phoneNumber)
      .whenComplete(notifyListeners);

  void setReportFilter(ReportFilter filter) {
    _reportFilter = filter;
    notifyListeners();
  }

  void dismissSuppressionDialog() {
    _suppressionDialogResult = null;
    notifyListeners();
  }

  /// Runs a typed phrase through the on-device rules. Voice input is planned
  /// to feed this same entry point; nothing listens to the microphone today.
  void checkPhrase(
    String phrase, {
    required VoidCallback onNavigateToEmergency,
  }) {
    if (phrase.trim().isEmpty) return;
    final result = PhraseGuardrail.analyze(phrase);

    if (result.recommendedPolicy == PolicyAction.suppress) {
      _suppressionDialogResult = result;
      notifyListeners();
      return;
    }
    _beginAlert(
      result,
      label: 'Typed phrase (manual entry)',
      seconds: result.recommendedPolicy == PolicyAction.escalate
          ? escalateSeconds
          : verifySeconds,
      onNavigateToEmergency: onNavigateToEmergency,
    );
  }

  /// The person overrides a "no alert" decision. A real emergency that
  /// happens to contain a chore, game or study word must still get out.
  void sendSuppressedAnyway({required VoidCallback onNavigateToEmergency}) {
    final suppressed = _suppressionDialogResult;
    if (suppressed == null) return;
    _suppressionDialogResult = null;
    _beginAlert(
      GuardrailResult(
        transcript: suppressed.transcript,
        detectedKeyword: 'Manual SOS',
        riskLevel: 'HIGH',
        confidence: 1.0,
        reasons:
            'Sent by the person after the phrase check said no alert. '
            'Check result: ${suppressed.reasons}',
        recommendedPolicy: PolicyAction.escalate,
        category: 'physical_danger',
        isEmergency: true,
      ),
      label: 'Typed phrase, sent anyway (manual entry)',
      seconds: escalateSeconds,
      onNavigateToEmergency: onNavigateToEmergency,
    );
  }

  /// Explicit Citizen Manual SOS
  void triggerManualSos({required VoidCallback onNavigateToEmergency}) {
    _beginAlert(
      const GuardrailResult(
        transcript: 'Manual Emergency SOS triggered by citizen',
        detectedKeyword: 'Manual SOS',
        riskLevel: 'CRITICAL',
        confidence: 1.0,
        reasons: 'Citizen tapped the Emergency SOS button',
        recommendedPolicy: PolicyAction.escalate,
        category: 'physical_danger',
        isEmergency: true,
      ),
      label: 'Manual SOS',
      seconds: escalateSeconds,
      onNavigateToEmergency: onNavigateToEmergency,
    );
  }

  /// Care Mode picture button that reports (Hurt, Fire, Lost). The
  /// call-the-caregiver needs never reach the countdown or a report.
  void triggerCareSos(
    CareNeed need, {
    required VoidCallback onNavigateToEmergency,
  }) {
    if (need.callsCaregiver) return;
    _beginAlert(
      GuardrailResult(
        transcript: 'Care Mode: ${need.phrase}',
        detectedKeyword: 'Manual SOS - ${need.label}',
        riskLevel: need.riskLevel!,
        confidence: 1.0,
        reasons: 'Tapped the "${need.label}" picture button in Care Mode',
        recommendedPolicy: PolicyAction.escalate,
        category: need.category!,
        isEmergency: true,
      ),
      label: 'Care Mode: ${need.label}',
      seconds: escalateSeconds,
      onNavigateToEmergency: onNavigateToEmergency,
    );
  }

  void _beginAlert(
    GuardrailResult result, {
    required String label,
    required int seconds,
    required VoidCallback onNavigateToEmergency,
  }) {
    _activeVerificationResult = result;
    _triggerLabel = label;
    _startEvidence();
    refreshLocation();
    _startCountdown(seconds);
    onNavigateToEmergency();
  }

  // Speech recognition and the recorder cannot share the microphone, so
  // listening pauses for the alert and comes back when it ends.
  Future<void> _startEvidence() async {
    if (_listeningOn) await _listener.stop();
    _recordingEvidence = await _repository.startEvidence();
    notifyListeners();
  }

  Future<void> _endEvidence() async {
    await _repository.cancelEvidence();
    _recordingEvidence = false;
    appResumed();
    notifyListeners();
  }

  void _ensureOutboxTimer() {
    _outboxTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => retryPending(),
    );
  }

  /// Re-sends queued reports. [force] also retries ones that hit the attempt cap.
  Future<void> retryPending({bool force = false}) async {
    if (_pendingReports == 0) return;
    final delivered = await _repository.flushOutbox(force: force);
    _pendingReports = await OutboxService.pendingCount();
    if (_pendingReports == 0) {
      _outboxTimer?.cancel();
      _outboxTimer = null;
    }
    if (delivered > 0) {
      if (_dispatchState == DispatchState.queued && _pendingReports == 0) {
        _dispatchState = DispatchState.sent;
      }
      _loadReports();
    }
    notifyListeners();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    _dispatchState = DispatchState.idle;
    _deadline = _now().add(Duration(seconds: seconds));
    _countdownSecondsRemaining = seconds;
    // ponytail: vibration only. An alert sound needs an audio plugin or
    // native code; add one when "loud by default" is built.
    HapticFeedback.vibrate();
    notifyListeners();

    // Counts down to a wall-clock deadline, not timer ticks, so an app that
    // was backgrounded catches up on its first tick instead of stalling.
    _countdownTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _tick(),
    );
  }

  void _tick() {
    final msLeft = _deadline!.difference(_now()).inMilliseconds;
    if (msLeft <= 0) {
      _countdownTimer?.cancel();
      _countdownSecondsRemaining = 0;
      dispatchEmergencyIncident();
      return;
    }
    final secondsLeft = (msLeft / 1000).ceil();
    if (secondsLeft != _countdownSecondsRemaining) {
      _countdownSecondsRemaining = secondsLeft;
      notifyListeners();
    }
  }

  void cancelVerification() {
    _countdownTimer?.cancel();
    _activeVerificationResult = null;
    _endEvidence();
    notifyListeners();
  }

  void confirmDispatchNow() {
    _countdownTimer?.cancel();
    _countdownSecondsRemaining = 0;
    dispatchEmergencyIncident();
  }

  Future<void> dispatchEmergencyIncident() async {
    final verification = _activeVerificationResult;
    // One report per alert: a double tap on "send now" must not file two.
    if (verification == null || _dispatchState != DispatchState.idle) return;
    _dispatchState = DispatchState.sending;
    notifyListeners();

    // 8 hex characters. With 4, two reports could share an id, and the
    // server's "already exists" answer would count the second as delivered.
    final reportId =
        'DNG-${_now().year}-${const Uuid().v4().substring(0, 8).toUpperCase()}';

    final audio = await _repository.uploadEvidence(reportId);
    _recordingEvidence = false;
    // The position asked for when this alert began, not the one from when
    // the app was opened. The read gives up by itself after a few seconds.
    // Without permission no position is coming, so there is nothing to wait for.
    if (_locationAllowed) await _locating;

    final newReport = IncidentReport(
      id: reportId,
      title: _triggerLabel,
      timestamp: _now(),
      status: IncidentStatus.submitted,
      // Where the phone is when that is known, else the registered address.
      locationAddress: _resolvedAddress ?? _userProfile.addressLine,
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
      accuracyMeters: currentLocation.accuracyMeters,
      triggerSource: _triggerLabel,
      audioDurationSec: audio.seconds,
      transcript: verification.transcript,
      verificationResult: verification,
      isEmergency: true,
      isSimulated: true,
      audioEvidenceUrl: audio.url,
      audioRecorded: audio.recorded,
    );

    _activeIncident = newReport;
    notifyListeners();

    final delivered = await _repository.submitReport(
      report: newReport,
      citizen: _userProfile,
    );

    if (delivered) {
      _dispatchState = DispatchState.sent;
    } else {
      await _repository.queueForRetry(newReport, _userProfile);
      _pendingReports = await OutboxService.pendingCount();
      _dispatchState = DispatchState.queued;
      _ensureOutboxTimer();
    }
    if (alertFromVoice) {
      // The person may not be looking at the phone: say what really happened.
      _notify(
        delivered ? 'Report sent' : 'Report saved on this phone',
        delivered
            ? 'The alert reached the DINIG dispatch system.'
            : 'It could not be sent yet. Open DINIG to retry, or call 911.',
      );
    }
    appResumed(); // listening paused for the recording; pick it up again
    notifyListeners();
  }

  Future<void> saveUserProfile(CitizenProfile profile) async {
    final phoneChanged = profile.phoneNumber != _userProfile.phoneNumber;
    _userProfile = profile;
    await PreferencesService.saveProfile(profile);
    notifyListeners();
    if (phoneChanged) {
      // My Reports is per phone number; never show the previous account's.
      _repository.clear();
      _loadReports();
    }
  }

  /// Removes the profile from this phone and stops the voice trigger, so
  /// nothing is filed under a signed-out account. Queued reports still send.
  Future<void> logout() async {
    await setListening(false);
    await saveUserProfile(const CitizenProfile());
  }

  bool _disposed = false;

  // Location, recording and network calls can finish after the screen that
  // owned this object is gone; their updates are then dropped.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _countdownTimer?.cancel();
    _outboxTimer?.cancel();
    _listener.stop();
    super.dispose();
  }
}
