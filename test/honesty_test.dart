// Guards the "no screen claims what the code does not do" rule.
// Widget tests return HTTP 400 for every request; the logged errors are noise.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dinig/data/models/citizen_profile.dart';
import 'package:dinig/data/models/incident_models.dart';
import 'package:dinig/ui/screens/emergency_contacts_screen.dart';
import 'package:dinig/ui/screens/emergency_detected_screen.dart';
import 'package:dinig/ui/screens/home_screen.dart';
import 'package:dinig/ui/screens/my_reports_screen.dart';
import 'package:dinig/ui/screens/onboarding_screen.dart';
import 'package:dinig/ui/screens/report_details_screen.dart';
import 'package:dinig/ui/screens/report_sent_screen.dart';
import 'package:dinig/ui/screens/settings_screen.dart';
import 'package:dinig/ui/theme/dinig_theme.dart';
import 'package:dinig/ui/view_models/dinig_view_model.dart';

/// A sent/queued alert with an incident, so Report Sent renders its tallest layout.
class _FinishedAlertViewModel extends DinigViewModel {
  final DispatchState _state;
  _FinishedAlertViewModel(this._state);

  @override
  DispatchState get dispatchState => _state;

  @override
  IncidentReport? get activeIncident => IncidentReport(
    id: 'DNG-TEST-0001',
    title: 'Manual SOS',
    timestamp: DateTime(2026, 10, 13, 9, 30),
    status: IncidentStatus.submitted,
    locationAddress: 'Barangay Test, Test City, Test Province',
  );
}

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1125, 2436); // 375x812 @3x
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: DinigTheme.lightTheme, home: screen),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

List<String> allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .toList();

void expectNoText(WidgetTester tester, List<String> banned) {
  final texts = allText(tester).map((t) => t.toLowerCase()).toList();
  for (final phrase in banned) {
    expect(
      texts.where((t) => t.contains(phrase.toLowerCase())),
      isEmpty,
      reason: 'screen should not contain "$phrase"',
    );
  }
}

void main() {
  // Before any DinigViewModel is built: it reads prefs on construction.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Home: no listening claims; typed phrase runs the rules', (
    tester,
  ) async {
    final vm = DinigViewModel();
    var navigated = 0;
    await pumpScreen(
      tester,
      HomeScreen(viewModel: vm, onTriggerEmergency: () => navigated++),
    );

    for (final banned in ['ARMED', 'Listening', 'Monitoring']) {
      expect(find.textContaining(banned), findsNothing);
    }
    expect(find.text('DEMO LOCATION'), findsOneWidget);
    expect(find.text('EMERGENCY SOS'), findsOneWidget);

    // Study phrase: the rules say no alert, so nothing navigates.
    await tester.enterText(
      find.byType(TextField),
      'Help naman sa assignment namin sa math',
    );
    await tester.ensureVisible(find.text('Check phrase'));
    await tester.tap(find.text('Check phrase'));
    await tester.pump();
    expect(vm.suppressionDialogResult, isNotNull);
    expect(navigated, 0);

    // Fire phrase: escalates with the 5 second countdown.
    await tester.enterText(find.byType(TextField), 'Tulong! May sunog!');
    await tester.ensureVisible(find.text('Check phrase'));
    await tester.tap(find.text('Check phrase'));
    await tester.pump();
    expect(navigated, 1);
    expect(vm.countdownSecondsRemaining, 5);

    expect(tester.takeException(), isNull);
    vm.dispose();
  });

  testWidgets(
    'Countdown: cancel is the largest, lowest control; no invented steps',
    (tester) async {
      final vm = DinigViewModel();
      vm.triggerManualSos(onNavigateToEmergency: () {});
      var cancelled = 0;
      await pumpScreen(
        tester,
        EmergencyDetectedScreen(
          viewModel: vm,
          onCancel: () => cancelled++,
          onReportSent: () {},
        ),
      );

      final cancel = find.widgetWithText(
        ElevatedButton,
        'CANCEL (FALSE ALARM)',
      );
      final send = find.widgetWithText(OutlinedButton, 'SEND IMMEDIATELY');
      expect(tester.getSize(cancel).height, greaterThanOrEqualTo(72));
      expect(
        tester.getSize(cancel).height,
        greaterThan(tester.getSize(send).height),
      );
      expect(
        tester.getTopLeft(cancel).dy,
        greaterThan(tester.getTopLeft(send).dy),
      );
      expectNoText(tester, ['Barangay 171', 'PNP', 'audio evidence buffer']);
      expect(find.text('Manual SOS'), findsOneWidget);
      expect(find.textContaining('not GPS'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(cancel);
      await tester.pump();
      expect(cancelled, 1);
      expect(vm.activeVerificationResult, isNull);
      vm.dispose();
    },
  );

  testWidgets(
    'Countdown in Care Mode: cancel still dominant, no mechanism block',
    (tester) async {
      final vm = DinigViewModel();
      await vm.saveUserProfile(const CitizenProfile(appFor: AppFor.child));
      vm.triggerCareSos(CareNeed.hurt, onNavigateToEmergency: () {});
      await pumpScreen(
        tester,
        EmergencyDetectedScreen(
          viewModel: vm,
          onCancel: () {},
          onReportSent: () {},
        ),
      );

      final cancel = find.widgetWithText(ElevatedButton, 'I AM OKAY');
      final send = find.widgetWithText(OutlinedButton, 'SEND HELP NOW');
      expect(tester.getSize(cancel).height, greaterThanOrEqualTo(72));
      expect(
        tester.getSize(cancel).height,
        greaterThan(tester.getSize(send).height),
      );
      expect(
        tester.getTopLeft(cancel).dy,
        greaterThan(tester.getTopLeft(send).dy),
      );
      expect(find.textContaining('When the countdown ends'), findsNothing);
      expect(tester.takeException(), isNull);
      vm.dispose();
    },
  );

  for (final state in [DispatchState.sent, DispatchState.queued]) {
    testWidgets('Report Sent (${state.name}): no live tracker, no overflow', (
      tester,
    ) async {
      final vm = _FinishedAlertViewModel(state);
      await pumpScreen(
        tester,
        ReportSentScreen(viewModel: vm, onReturnHome: () {}),
      );

      expect(find.text('TRACK LIVE DISPATCH MAP'), findsNothing);
      expect(find.text('Registered address'), findsOneWidget);
      expect(find.textContaining('not GPS'), findsOneWidget);
      expect(
        find.textContaining('cannot show responder status'),
        state == DispatchState.sent ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
      vm.dispose();
    });
  }

  testWidgets('Report Details: no GPS lock, no percentages, no timeline', (
    tester,
  ) async {
    final report = IncidentReport(
      id: 'DNG-TEST-0002',
      title: 'Typed phrase (manual entry)',
      timestamp: DateTime(2026, 10, 13, 9, 30),
      status: IncidentStatus.submitted,
      locationAddress: 'Barangay Test, Test City, Test Province',
      audioRecorded: false,
      transcript: 'Tulong! May sunog!',
      verificationResult: const GuardrailResult(
        transcript: 'Tulong! May sunog!',
        detectedKeyword: 'Tulong',
        riskLevel: 'CRITICAL',
        confidence: 0.985,
        reasons: "Fire words found ('sunog'). Escalating.",
        recommendedPolicy: PolicyAction.escalate,
      ),
    );
    await pumpScreen(
      tester,
      ReportDetailsScreen(report: report, onBack: () {}),
    );

    expectNoText(tester, [
      'GPS COORDINATE LOCK',
      'On-Device',
      '%',
      'Chronology',
      'Barangay 171',
    ]);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Decision: Send now'), findsOneWidget);
    expect(
      find.text('Placeholder audio tone (not a recording)'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Onboarding makes no privacy, GPS or permission claims', (
    tester,
  ) async {
    var continued = 0;
    await pumpScreen(tester, OnboardingScreen(onContinue: () => continued++));

    expectNoText(tester, [
      'on-device keyword spotter',
      'Data Privacy',
      'permission',
      'Enable',
    ]);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    expect(continued, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings has no monitoring, sensitivity or privacy claims', (
    tester,
  ) async {
    final vm = DinigViewModel();
    await pumpScreen(
      tester,
      SettingsScreen(viewModel: vm, onSwitchAccount: () {}, onLogout: () {}),
    );

    expectNoText(tester, [
      'on-device keyword spotter',
      'Data Privacy',
      'Voice Trigger Monitoring',
      'Sensitivity',
    ]);
    expect(find.text('PROTOTYPE STATUS'), findsOneWidget);
    expect(tester.takeException(), isNull);
    vm.dispose();
  });

  testWidgets('Emergency contacts: only 911 and the personal contact', (
    tester,
  ) async {
    final vm = DinigViewModel();
    await pumpScreen(tester, EmergencyContactsScreen(viewModel: vm));

    expectNoText(tester, ['171', 'PNP', 'BFP', '117', '0917']);
    expect(find.textContaining('911'), findsOneWidget);
    expect(
      find.text('Barangay hotline: not set up in this prototype.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    vm.dispose();
  });

  testWidgets('My Reports: new phone number shows the empty state', (
    tester,
  ) async {
    final vm = DinigViewModel();
    await pumpScreen(
      tester,
      MyReportsScreen(viewModel: vm, onSelectReport: (_) {}),
    );

    expect(find.text('No reports from this phone number yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    vm.dispose();
  });
}
