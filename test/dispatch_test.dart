import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dinig/data/models/citizen_profile.dart';
import 'package:dinig/data/models/incident_models.dart';
import 'package:dinig/data/repositories/incident_repository.dart';
import 'package:dinig/ui/view_models/dinig_view_model.dart';

/// No network: records what would be sent and answers as told.
class FakeRepository extends IncidentRepository {
  bool deliver = true;
  final sent = <IncidentReport>[];

  @override
  Future<List<IncidentReport>> loadReports(String phone) async => [];

  bool microphoneAllowed = false;
  bool recording = false;

  @override
  Future<bool> startEvidence() async => recording = microphoneAllowed;

  @override
  Future<void> cancelEvidence() async => recording = false;

  @override
  Future<({String? url, bool recorded, int seconds})> uploadEvidence(
    String reportId,
  ) async {
    final recorded = recording;
    recording = false;
    return (url: null, recorded: recorded, seconds: 5);
  }

  @override
  Future<bool> submitReport({
    required IncidentReport report,
    required CitizenProfile citizen,
  }) async {
    sent.add(report);
    return deliver;
  }
}

/// The index the location plugin sends for each permission answer.
abstract final class LocationPermissionIndex {
  static const whileInUse = 2;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // testWidgets, not test(): the alert vibrates through a platform channel.
  Future<(DinigViewModel, FakeRepository)> start(WidgetTester tester) async {
    final repo = FakeRepository();
    final vm = DinigViewModel(repository: repo);
    await tester.pump();
    return (vm, repo);
  }

  testWidgets('delivered report shows sent; one report even on a double tap',
      (tester) async {
    final (vm, repo) = await start(tester);
    vm.triggerManualSos(onNavigateToEmergency: () {});
    vm.confirmDispatchNow();
    vm.confirmDispatchNow();
    await tester.pump();

    expect(repo.sent, hasLength(1));
    expect(vm.dispatchState, DispatchState.sent);
    final report = repo.sent.single;
    expect(report.title, 'Manual SOS');
    expect(report.triggerSource, 'Manual SOS');
    expect(report.id, matches(RegExp(r'^DNG-\d{4}-[0-9A-F]{8}$')));
    // Phone sign-in profiles have no barangay: never ", , ".
    expect(report.locationAddress, 'Address not set');
    vm.dispose();
  });

  testWidgets('failed send is queued, never shown as sent', (tester) async {
    final (vm, repo) = await start(tester);
    repo.deliver = false;
    vm.triggerManualSos(onNavigateToEmergency: () {});
    vm.confirmDispatchNow();
    await tester.pump();
    await tester.pump();

    expect(vm.dispatchState, DispatchState.queued);
    expect(vm.pendingReports, 1);
    vm.dispose();
  });

  testWidgets('countdown follows the wall clock, so a suspended app catches up',
      (tester) async {
    var now = DateTime(2026, 10, 13, 12);
    final repo = FakeRepository();
    final vm = DinigViewModel(repository: repo, now: () => now);
    await tester.pump();

    vm.triggerManualSos(onNavigateToEmergency: () {});
    expect(vm.countdownSecondsRemaining, 5);

    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(vm.countdownSecondsRemaining, 3);
    expect(repo.sent, isEmpty);

    // Backgrounded for 30 s: the first tick after resume sends once.
    now = now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(repo.sent, hasLength(1));
    expect(vm.dispatchState, DispatchState.sent);
    vm.dispose();
  });

  testWidgets('a report carries the position read during its alert',
      (tester) async {
    // The phone's location plugin, answering as the test says.
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    Map<String, Object>? fix = {'latitude': 10.5, 'longitude': 120.5, 'accuracy': 5.0};
    var delay = Duration.zero;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          return LocationPermissionIndex.whileInUse;
        case 'getCurrentPosition':
          if (delay > Duration.zero) await Future<void>.delayed(delay);
          if (fix == null) throw PlatformException(code: 'no fix');
          return fix;
      }
      return null; // no last known position
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    final (vm, repo) = await start(tester);
    await vm.refreshLocation();
    expect(vm.currentLocation.isLive, isTrue);
    expect(vm.currentLocation.latitude, 10.5);
    expect(vm.locationAllowed, isTrue);

    // A read that fails keeps the real position, not the demo coordinate.
    fix = null;
    await vm.refreshLocation();
    expect(vm.currentLocation.latitude, 10.5);

    // The phone moved, and the new position arrives after "send now".
    fix = {'latitude': 11.5, 'longitude': 121.5, 'accuracy': 8.0};
    delay = const Duration(seconds: 2);
    vm.triggerManualSos(onNavigateToEmergency: () {});
    vm.confirmDispatchNow();
    await tester.pump(const Duration(seconds: 1));
    expect(repo.sent, isEmpty); // waiting for the position
    await tester.pump(const Duration(seconds: 2));
    expect(repo.sent.single.latitude, 11.5);
    expect(repo.sent.single.accuracyMeters, 8.0);
    vm.dispose();
  });

  testWidgets('cancel inside the window sends nothing', (tester) async {
    var now = DateTime(2026, 10, 13, 12);
    final repo = FakeRepository();
    final vm = DinigViewModel(repository: repo, now: () => now);
    await tester.pump();

    vm.triggerManualSos(onNavigateToEmergency: () {});
    vm.cancelVerification();
    now = now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));

    expect(repo.sent, isEmpty);
    expect(vm.dispatchState, DispatchState.idle);
    vm.dispose();
  });

  testWidgets('a suppressed phrase can still be sent', (tester) async {
    final (vm, repo) = await start(tester);
    var navigated = 0;

    vm.checkPhrase(
      'Help naman sa assignment namin sa math',
      onNavigateToEmergency: () => navigated++,
    );
    expect(vm.suppressionDialogResult, isNotNull);
    expect(vm.activeVerificationResult, isNull);
    expect(navigated, 0);

    vm.sendSuppressedAnyway(onNavigateToEmergency: () => navigated++);
    expect(navigated, 1);
    expect(vm.suppressionDialogResult, isNull);
    expect(vm.countdownSecondsRemaining, 5);
    vm.confirmDispatchNow();
    await tester.pump();

    final report = repo.sent.single;
    expect(report.transcript, 'Help naman sa assignment namin sa math');
    expect(report.title, contains('sent anyway'));
    expect(report.title, isNot(contains('Voice')));
    vm.dispose();
  });

  testWidgets('Care Mode call-the-caregiver needs never start a report',
      (tester) async {
    final (vm, repo) = await start(tester);
    for (final need in [CareNeed.scared, CareNeed.grownUp]) {
      vm.triggerCareSos(need, onNavigateToEmergency: () => fail('navigated'));
    }
    expect(vm.activeVerificationResult, isNull);
    await tester.pump(const Duration(seconds: 11));
    expect(repo.sent, isEmpty);
    vm.dispose();
  });
}
