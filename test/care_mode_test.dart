import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dinig/data/models/citizen_profile.dart';
import 'package:dinig/data/models/incident_models.dart';
import 'package:dinig/main.dart';
import 'package:dinig/ui/screens/auth_screen.dart';
import 'package:dinig/ui/screens/care_home_screen.dart';
import 'package:dinig/ui/screens/help_card_screen.dart';
import 'package:dinig/ui/screens/welcome_screen.dart';
import 'package:dinig/ui/view_models/dinig_view_model.dart';

import 'dispatch_test.dart' show FakeRepository;

const _caregiver = CitizenProfile(
  fullName: 'Ana Reyes',
  emergencyContactName: 'Rosa Reyes',
  emergencyContactPhone: '+63 917 000 0000',
  appFor: AppFor.child,
);

/// 375x812 viewport, empty prefs, and a view model holding [profile].
Future<DinigViewModel> _phoneVm(
  WidgetTester tester, [
  CitizenProfile profile = const CitizenProfile(),
]) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1125, 2436); // 375x812 @3x
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final vm = DinigViewModel();
  await tester.runAsync(() async {
    await vm.ready;
    await vm.saveUserProfile(profile);
  });
  return vm;
}

void main() {
  test('profile keeps Care Mode choice and support notes through JSON', () {
    const p = CitizenProfile(
      appFor: AppFor.child,
      supportNotes: 'speaks few words',
    );
    final back = CitizenProfile.fromJson(p.toJson());
    expect(back.appFor, AppFor.child);
    expect(back.appFor.isCareMode, isTrue);
    expect(back.supportNotes, 'speaks few words');
    expect(const CitizenProfile().appFor.isCareMode, isFalse);
  });

  test('selected support chips survive a profile JSON round trip', () {
    final picked = [careSupportOptions[0], careSupportOptions[3], careSupportOptions[6]];
    final p = CitizenProfile(
      appFor: AppFor.dependent,
      supportNotes: picked.join('; '),
    );
    final back = CitizenProfile.fromJson(p.toJson());
    expect(back.supportNotes.split('; '), picked);
    expect(careSupportOptions, hasLength(7));
  });

  testWidgets('Hurt starts the countdown with the right category',
      (tester) async {
    final vm = await _phoneVm(tester);
    var navigated = 0;

    await tester.pumpWidget(MaterialApp(
      home: CareHomeScreen(
        viewModel: vm,
        onTriggerEmergency: () => navigated++,
        onCaregiverHold: () {},
      ),
    ));

    // Every picture button is a >=44px tap target.
    for (final need in CareNeed.values) {
      final card = tester.getSize(find.ancestor(
        of: find.text(need.label),
        matching: find.byType(InkWell),
      ));
      expect(card.height, greaterThanOrEqualTo(44));
      expect(card.width, greaterThanOrEqualTo(44));
    }

    await tester.tap(find.text('Hurt'));
    await tester.pump();

    expect(navigated, 1);
    final r = vm.activeVerificationResult!;
    expect(r.category, 'medical_emergency');
    expect(r.recommendedPolicy, PolicyAction.escalate);
    expect(r.detectedKeyword, contains('Manual'));
    expect(vm.countdownSecondsRemaining, 5);
    expect(tester.takeException(), isNull);

    // Cancels the countdown timer before the framework checks for leaks.
    vm.dispose();
  });

  testWidgets('Scared and Need a grown-up only call: no countdown, no report',
      (tester) async {
    final vm = await _phoneVm(tester, _caregiver);
    var navigated = 0;

    await tester.pumpWidget(MaterialApp(
      home: CareHomeScreen(
        viewModel: vm,
        onTriggerEmergency: () => navigated++,
        onCaregiverHold: () {},
      ),
    ));

    for (final label in ['Scared', 'Need a grown-up']) {
      await tester.tap(find.text(label));
      // The platform channel answers in real time, not fake time.
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      // The dialer is unavailable in tests, so the app says so.
      expect(find.textContaining('Cannot place a call'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
          .clearSnackBars();
      await tester.pump();
    }

    expect(navigated, 0);
    expect(vm.activeVerificationResult, isNull);
    expect(vm.dispatchState, DispatchState.idle);
    expect(vm.reports, isEmpty);
    expect(tester.takeException(), isNull);
    vm.dispose();
  });

  testWidgets('captions say what each button does', (tester) async {
    var vm = await _phoneVm(tester, _caregiver);
    await tester.pumpWidget(MaterialApp(
      home: CareHomeScreen(
        viewModel: vm,
        onTriggerEmergency: () {},
        onCaregiverHold: () {},
      ),
    ));

    expect(find.text('Calls Rosa Reyes'), findsNWidgets(2));
    expect(find.text('Tells the barangay'), findsNWidgets(2)); // Hurt, Fire
    expect(find.text('Tells the barangay you are lost'), findsOneWidget);
    expect(find.textContaining('where you are'), findsNothing);
    vm.dispose();

    vm = await _phoneVm(
      tester,
      _caregiver.copyWith(emergencyContactPhone: ''),
    );
    await tester.pumpWidget(MaterialApp(
      home: CareHomeScreen(
        viewModel: vm,
        onTriggerEmergency: () {},
        onCaregiverHold: () {},
      ),
    ));
    expect(find.text('Calls 911'), findsNWidgets(2));
    expect(find.textContaining('Rosa'), findsNothing);
    expect(tester.takeException(), isNull);
    vm.dispose();
  });

  testWidgets('holding the DINIG title for 3 seconds opens the caregiver menu',
      (tester) async {
    final vm = await _phoneVm(tester);
    var held = 0;
    await tester.pumpWidget(MaterialApp(
      home: CareHomeScreen(
        viewModel: vm,
        onTriggerEmergency: () {},
        onCaregiverHold: () => held++,
      ),
    ));
    final title = tester.getCenter(find.text('DINIG'));

    // A tap and a 1-second press do nothing.
    await tester.tap(find.text('DINIG'));
    await tester.pump();
    var g = await tester.startGesture(title);
    await tester.pump(const Duration(seconds: 1));
    await g.up();
    await tester.pump();
    expect(held, 0);

    g = await tester.startGesture(title);
    await tester.pump(const Duration(seconds: 3, milliseconds: 100));
    await g.up();
    await tester.pump();
    expect(held, 1);
    vm.dispose();
  });

  testWidgets('a caregiver can log out from the picture screen',
      (tester) async {
    await _phoneVm(tester); // viewport only; the prefs are replaced below
    SharedPreferences.setMockInitialValues({
      'dinig_citizen_profile': jsonEncode(_caregiver
          .copyWith(phoneNumber: '0000', isRegistered: true, isVerified: true)
          .toJson()),
    });
    final vm = DinigViewModel(repository: FakeRepository());
    await tester.pumpWidget(MaterialApp(home: DinigMainShell(viewModel: vm)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CareHomeScreen), findsOneWidget);
    expect(find.text('Log out'), findsNothing); // not one tap away for a child

    final g = await tester.startGesture(tester.getCenter(find.text('DINIG')));
    await tester.pump(const Duration(seconds: 3, milliseconds: 100));
    await g.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    expect(vm.userProfile.isRegistered, isTrue); // nothing until confirmed

    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(vm.userProfile.isRegistered, isFalse);
    expect(vm.userProfile.appFor, AppFor.myself);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('dinig_citizen_profile'), isNot(contains('Ana Reyes')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  group('HelpCardScreen', () {
    final all = _caregiver.copyWith(
      supportNotes: careSupportOptions.join('; '),
      medicalNotes: 'Asthma',
    );

    Future<void> show(
      WidgetTester tester,
      CitizenProfile p,
      DispatchState s, {
      VoidCallback? onRetry,
    }) async {
      await _phoneVm(tester); // viewport + prefs only
      await tester.pumpWidget(MaterialApp(
        home: HelpCardScreen(
          profile: p,
          dispatchState: s,
          onRetry: onRetry ?? () {},
          onDone: () {},
        ),
      ));
    }

    testWidgets('sent', (tester) async {
      await show(tester, all.copyWith(supportNotes: 'Does not speak; May run away'),
          DispatchState.sent);
      expect(find.text('Alert sent'), findsOneWidget);
      expect(find.text('The alert reached the DINIG dispatch system.'), findsOneWidget);
      expect(find.text('Retry now'), findsNothing);
      expect(find.text('Does not speak'), findsOneWidget);
      expect(find.text('May run away'), findsOneWidget);
      expect(find.text('Show this to the helper'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Back to pictures'), 300);
      expect(
        find.text('This card is shown on this phone. It was not sent with the alert.'),
        findsOneWidget,
      );
      expect(find.text('Call Rosa Reyes'), findsOneWidget);
      expect(find.text('Back to pictures'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('queued never claims the alert was sent', (tester) async {
      var retried = 0;
      await show(tester, all, DispatchState.queued, onRetry: () => retried++);
      expect(find.text('Saved on this phone'), findsOneWidget);
      expect(find.textContaining('Alert sent'), findsNothing);
      expect(find.textContaining('reached'), findsNothing);
      expect(find.textContaining('urgent, call 911'), findsOneWidget);
      for (final option in careSupportOptions) {
        expect(find.text(option), findsOneWidget);
      }
      await tester.tap(find.text('Retry now'));
      expect(retried, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sending and idle say sending, with no retry', (tester) async {
      for (final s in [DispatchState.sending, DispatchState.idle]) {
        await show(tester, all, s);
        expect(find.text('Sending your alert…'), findsOneWidget);
        expect(find.text('Retry now'), findsNothing);
        expect(find.textContaining('Alert sent'), findsNothing);
      }
    });

    testWidgets('long caregiver name and seven chips do not overflow',
        (tester) async {
      const longName = 'Dr. Maria Concepcion Villanueva-Santos de la Cruz';
      final p = all.copyWith(emergencyContactName: longName);
      await show(tester, p, DispatchState.queued);
      await tester.scrollUntilVisible(find.text('Call $longName'), 300);
      await tester.scrollUntilVisible(find.text('Back to pictures'), 300);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no caregiver phone falls back to Call 911', (tester) async {
      await show(
        tester,
        all.copyWith(emergencyContactPhone: ''),
        DispatchState.sent,
      );
      await tester.scrollUntilVisible(find.text('Call 911'), 300);
      expect(find.text('Call 911'), findsOneWidget);
    });
  });

  testWidgets('Care Mode registration needs the caregiver phone',
      (tester) async {
    final vm = await _phoneVm(tester);
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(
        viewModel: vm,
        onAuthenticated: () {},
        startOnRegister: true,
      ),
    ));

    await tester.tap(find.text('A child'));
    await tester.pump();
    expect(find.text('This is what a responder will see'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'First Name'), 'Ana');
    await tester.enterText(find.widgetWithText(TextField, 'Last Name'), 'Reyes');
    await tester.enterText(
        find.widgetWithText(TextField, 'Mobile Phone Number'), '09170000000');

    final list = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(find.text('Caregiver phone (required)'), 200,
        scrollable: list);
    await tester.scrollUntilVisible(find.text('Ask before touching'), 200,
        scrollable: list);
    await tester.tap(find.text('Ask before touching'));
    await tester.pump();
    expect(find.text('This is what a responder will see'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('REGISTER RESIDENT PROFILE'), 200,
        scrollable: list);
    await tester.tap(find.text('REGISTER RESIDENT PROFILE'));
    await tester.pump();

    expect(
      find.text("Please add the caregiver's phone number. Care Mode calls it."),
      findsOneWidget,
    );
    expect(vm.userProfile.isRegistered, isFalse);
    expect(tester.takeException(), isNull);
    vm.dispose();
  });
}
