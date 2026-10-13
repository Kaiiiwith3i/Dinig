import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dinig/data/models/incident_models.dart';
import 'package:dinig/data/services/audio_evidence_service.dart';
import 'package:dinig/data/services/listening_service.dart';
import 'package:dinig/ui/view_models/dinig_view_model.dart';

import 'dispatch_test.dart' show FakeRepository;

/// No microphone: [start] answers as told.
class FakeListener extends ListeningService {
  bool available = true;
  int starts = 0;

  @override
  Future<bool> start() async {
    starts++;
    return available;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // testWidgets so the 2 s "let the speaker finish" timer runs on fake time.
  testWidgets('only an utterance with a trigger word is passed on, once',
      (tester) async {
    final heard = <String>[];
    var now = DateTime(2026, 10, 13, 12);
    final service = ListeningService(now: () => now)..onPhrase = heard.add;
    Future<void> wait(int seconds) async {
      now = now.add(Duration(seconds: seconds));
      await tester.pump(Duration(seconds: seconds));
    }

    service.handleWords('what time is the game tonight');
    await wait(4);
    expect(heard, isEmpty);

    service.handleWords('what time is the game tonight help');
    service.handleWords('what time is the game tonight help there is a fire');
    await wait(3);
    // Talk from before the pause is not part of the phrase.
    expect(heard, ['help there is a fire']);

    // The session keeps running; the same words must not trigger again.
    service.handleWords(
      'what time is the game tonight help there is a fire okay thanks',
    );
    await wait(3);
    expect(heard, hasLength(1));

    service.handleWords(
      'what time is the game tonight help there is a fire okay thanks tulong',
      isFinal: true,
    );
    expect(heard, hasLength(2));
    expect(heard.last, contains('tulong'));
  });

  test('an empty recording is told apart from a real one', () {
    // What iOS left on a voice-triggered report: 4,096 bytes, no sound.
    final headerOnly = Uint8List(4096)
      ..setRange(0, 4, 'RIFF'.codeUnits)
      ..setRange(8, 12, 'WAVE'.codeUnits);
    expect(AudioEvidenceService.wavDataBytes(headerOnly), 0);
    expect(
      AudioEvidenceService.wavDataBytes(
        AudioEvidenceService.generateEmergencyWavClip(durationSeconds: 1),
      ),
      32000,
    );
  });

  test('a long transcript is cut to the words around the trigger', () {
    final words = 'a b c d e f g h i j help me please'.split(' ');
    expect(ListeningService.aroundTrigger(words), 'e f g h i j help me please');
  });

  Future<(DinigViewModel, FakeRepository, List<String>)> start(
    WidgetTester tester,
    FakeListener listener,
  ) async {
    final repo = FakeRepository();
    final notes = <String>[];
    final vm = DinigViewModel(
      repository: repo,
      listener: listener,
      notify: (title, body) async => notes.add('$title | $body'),
    );
    await tester.pump();
    return (vm, repo, notes);
  }

  testWidgets('a heard emergency starts the countdown, notifies, and sends',
      (tester) async {
    var now = DateTime(2026, 10, 13, 12);
    final repo = FakeRepository();
    final notes = <String>[];
    final vm = DinigViewModel(
      repository: repo,
      now: () => now,
      listener: FakeListener(),
      notify: (title, body) async => notes.add('$title | $body'),
    );
    await tester.pump();
    var shown = 0;
    vm.onVoiceAlert = () => shown++;

    vm.heardPhrase('help there is a fire');
    expect(shown, 1);
    expect(vm.alertFromVoice, isTrue);
    expect(vm.countdownSecondsRemaining, 5);
    expect(vm.activeVerificationResult!.recommendedPolicy, PolicyAction.escalate);
    expect(notes.single, contains('Sending a report in 5 seconds'));

    // A second phrase during the alert changes nothing.
    vm.heardPhrase('help');
    expect(shown, 1);

    // Nobody cancels: it sends when the countdown ends.
    now = now.add(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(repo.sent.single.title, 'Voice trigger ("Help")');
    expect(notes.last, startsWith('Report sent'));
    vm.dispose();
  });

  testWidgets('cancelling a heard alert sends nothing and drops the recording',
      (tester) async {
    final (vm, repo, _) = await start(tester, FakeListener());
    repo.microphoneAllowed = true;

    vm.heardPhrase('tulong');
    await tester.pump();
    expect(vm.recordingEvidence, isTrue);

    vm.cancelVerification();
    await tester.pump();
    expect(vm.recordingEvidence, isFalse);
    expect(repo.recording, isFalse);
    await tester.pump(const Duration(minutes: 1));
    expect(repo.sent, isEmpty);
    vm.dispose();
  });

  testWidgets('a report says truthfully whether its audio is a recording',
      (tester) async {
    final (vm, repo, _) = await start(tester, FakeListener());

    vm.triggerManualSos(onNavigateToEmergency: () {});
    vm.confirmDispatchNow();
    await tester.pump();
    expect(repo.sent.last.audioRecorded, isFalse);
    // No location plugin in tests: the demo point, flagged as such.
    expect(repo.sent.last.hasDemoLocation, isTrue);
    expect(vm.currentLocation.isLive, isFalse);

    repo.microphoneAllowed = true;
    vm.triggerManualSos(onNavigateToEmergency: () {});
    await tester.pump();
    vm.confirmDispatchNow();
    await tester.pump();
    expect(repo.sent.last.audioRecorded, isTrue);
    vm.dispose();
  });

  testWidgets('a heard joke or homework phrase starts nothing', (tester) async {
    final (vm, repo, notes) = await start(tester, FakeListener());
    vm.onVoiceAlert = () => fail('no alert expected');

    vm.heardPhrase('help me with my homework assignment');
    expect(vm.activeVerificationResult, isNull);
    expect(vm.suppressionDialogResult, isNull);
    expect(vm.lastHeard, contains('no alert'));
    expect(notes, isEmpty);
    await tester.pump(const Duration(seconds: 11));
    expect(repo.sent, isEmpty);
    vm.dispose();
  });

  testWidgets('a failed voice report says saved, not sent', (tester) async {
    final (vm, repo, notes) = await start(tester, FakeListener());
    repo.deliver = false;
    vm.heardPhrase('tulong may sunog');
    vm.confirmDispatchNow();
    await tester.pump();
    await tester.pump();
    expect(vm.dispatchState, DispatchState.queued);
    expect(notes.last, startsWith('Report saved on this phone'));
    vm.dispose();
  });

  testWidgets('the switch reports the truth when listening cannot start',
      (tester) async {
    final listener = FakeListener()..available = false;
    final (vm, _, _) = await start(tester, listener);

    await tester.runAsync(() => vm.setListening(true));
    expect(vm.listeningOn, isFalse);
    expect(vm.listeningProblem, contains('could not start'));

    listener.available = true;
    await tester.runAsync(() => vm.setListening(true));
    expect(vm.listeningOn, isTrue);
    expect(vm.listeningProblem, isNull);

    // Coming back to the front picks listening up again.
    final before = listener.starts;
    vm.appResumed();
    expect(listener.starts, before + 1);
    vm.dispose();
  });

  testWidgets('when the engine stops answering the app says so', (tester) async {
    final listener = FakeListener();
    final (vm, _, notes) = await start(tester, listener);

    listener.onEngineState!(false);
    expect(vm.listeningProblem, contains('not answering'));
    expect(notes.single, startsWith('DINIG is not listening'));

    listener.onEngineState!(true);
    expect(vm.listeningProblem, isNull);
    vm.dispose();
  });
}
