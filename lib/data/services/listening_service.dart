import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'phrase_guardrail.dart';

/// Continuous listening through the phone's built-in speech recognition.
///
/// Speech is turned into text by the operating system's speech engine. It
/// asks for on-device recognition first; a phone without the on-device model
/// falls back to the engine's default, which may send audio to its servers
/// (Apple's, on an iPhone). This class only looks at the text: a phrase is
/// passed on when it contains a trigger word (Help, Tulong, Saklolo).
/// Everything else is dropped and never leaves this object.
class ListeningService {
  ListeningService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final SpeechToText _speech = SpeechToText();
  final DateTime Function() _now;
  DateTime? _lastWordsAt;

  bool _wanted = false;
  bool _active = false; // a session this class started is running
  bool _onDevice = true;
  int _failures = 0;
  List<String> _tokens = const [];
  int _handled = 0; // words of the running session already dealt with
  Timer? _settle;
  Timer? _restart;
  double _peak = -100;

  /// Called once per utterance that contains a trigger word.
  void Function(String phrase)? onPhrase;

  /// Called with false when the speech engine keeps failing with something
  /// other than silence, and with true when it produces words again.
  void Function(bool responding)? onEngineState;

  /// Starts listening and keeps restarting sessions until [stop]. Safe to
  /// call again while running. Returns false when the microphone or speech
  /// permission is refused, or the device has no speech engine.
  Future<bool> start() async {
    _wanted = true;
    bool available;
    try {
      available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
    } catch (_) {
      available = false;
    }
    if (!available) {
      _wanted = false;
      return false;
    }
    // A fresh start (the switch, or the app coming back to the front) gets
    // a clean slate; real faults show up again within a few seconds.
    if (_failures > 0) {
      _failures = 0;
      onEngineState?.call(true);
    }
    await _listen();
    return true;
  }

  Future<void> stop() async {
    final wasActive = _active;
    _wanted = false;
    _active = false;
    _settle?.cancel();
    _settle = null;
    _restart?.cancel();
    try {
      wasActive ? await _speech.cancel() : await _speech.stop();
    } catch (_) {}
    // The speech engine finishes its session a moment after this returns and
    // then switches the phone's audio off once more. A recorder started
    // before that captures nothing (seen: a header-only 4,096-byte file on a
    // voice-triggered report), so give it time to let go of the microphone.
    if (wasActive) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
  }

  Future<void> _listen() async {
    if (!_wanted || _active) return;
    _active = true;
    _tokens = const [];
    _handled = 0;
    try {
      // The plugin's own "listening" flag can be left on by a status event
      // that arrives after an error; clear it or it refuses to start.
      if (_speech.isListening) await _speech.cancel();
      await _speech.listen(
        onResult: (r) => handleWords(r.recognizedWords, isFinal: r.finalResult),
        onSoundLevelChange: (level) {
          if (level > _peak) _peak = level;
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
          onDevice: _onDevice,
        ),
      );
    } catch (e) {
      debugPrint('ListeningService: listen failed: $e');
      _active = false;
      _scheduleRestart(const Duration(seconds: 2));
    }
  }

  /// Takes the running transcript of the current session. Public so the
  /// trigger logic can be tested without a microphone.
  @visibleForTesting
  void handleWords(String words, {bool isFinal = false}) {
    if (_failures > 0) {
      _failures = 0;
      onEngineState?.call(true);
    }
    final tokens = words.trim().split(RegExp(r'\s+'));
    // Word count only: what was said is never logged.
    debugPrint('ListeningService: hearing (${tokens.length} words)');
    if (tokens.length < _handled) _handled = 0; // the engine started over
    // A pause of 3 s or more starts a new utterance: what was said before it
    // is not context for a trigger word said after it.
    final now = _now();
    final last = _lastWordsAt;
    if (last != null &&
        _settle == null &&
        now.difference(last) >= const Duration(seconds: 3) &&
        _tokens.length <= tokens.length &&
        _tokens.length > _handled) {
      _handled = _tokens.length;
    }
    _lastWordsAt = now;
    _tokens = tokens;
    if (!hasTrigger(tokens.sublist(_handled).join(' '))) return;
    if (isFinal) {
      _emit();
    } else {
      // Let the speaker finish ("Tulong... may sunog") before deciding.
      _settle ??= Timer(const Duration(seconds: 2), _emit);
    }
  }

  // The session is left running on purpose: stopping and restarting the
  // microphone is refused by iOS while the app is in the background.
  void _emit() {
    _settle?.cancel();
    _settle = null;
    final fresh = _tokens.sublist(_handled);
    _handled = _tokens.length;
    if (hasTrigger(fresh.join(' '))) onPhrase?.call(aroundTrigger(fresh));
  }

  // The engine ends a session after a pause or a time limit; listening is
  // meant to be continuous, so every end schedules the next session.
  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _active = false;
      _scheduleRestart(_retryDelay(const Duration(milliseconds: 300)));
    }
  }

  // Once the engine is clearly failing, try every 10 s instead of at once.
  Duration _retryDelay(Duration normal) =>
      _failures >= 3 ? const Duration(seconds: 10) : normal;

  void _onError(SpeechRecognitionError error) {
    // The peak level tells a silent microphone apart from an engine fault.
    debugPrint('ListeningService: ${error.errorMsg} (peak level $_peak)');
    _peak = -100;
    _active = false;
    // What the engine reports when a session ends without speech. On iOS
    // "retry" is the usual answer to a few seconds of silence.
    final silence = const {
      'error_no_match',
      'error_speech_timeout',
      'error_retry',
      'error_request_cancelled',
    }.contains(error.errorMsg);
    if (_onDevice && error.errorMsg.startsWith('error_unknown')) {
      // No on-device speech model on this phone: use the engine's default.
      _onDevice = false;
    } else if (!silence && ++_failures == 3) {
      onEngineState?.call(false);
    }
    _scheduleRestart(_retryDelay(const Duration(seconds: 1)));
  }

  void _scheduleRestart(Duration delay) {
    if (!_wanted) return;
    _restart?.cancel();
    _restart = Timer(delay, _listen);
  }

  static bool hasTrigger(String text) => PhraseGuardrail.triggerWords.any(
    (w) => PhraseGuardrail.containsPhrase(text, w),
  );

  /// A session's transcript can hold minutes of talk. Only the words near
  /// the last trigger word are about the emergency.
  /// ponytail: fixed window of 6 words before the trigger; use sentence
  /// boundaries if the engine starts returning punctuation reliably.
  static String aroundTrigger(List<String> words) {
    final last = words.lastIndexWhere(hasTrigger);
    if (last < 0) return words.join(' ');
    return words.sublist(last > 6 ? last - 6 : 0).join(' ');
  }
}
