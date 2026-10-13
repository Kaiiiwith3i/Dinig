import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dinig/data/models/citizen_profile.dart';
import 'package:dinig/main.dart';
import 'package:dinig/ui/components/guide_tour.dart';
import 'package:dinig/ui/screens/emergency_detected_screen.dart';
import 'package:dinig/ui/view_models/dinig_view_model.dart';

import 'dispatch_test.dart' show FakeRepository;

void main() {
  const resident = CitizenProfile(
    fullName: 'Test Resident',
    phoneNumber: '0000',
    barangay: 'Brgy. Test',
    isRegistered: true,
    isLoggedIn: true,
    isVerified: true,
  );

  // Opens the app past registration with [profile] stored, at 375x812.
  Future<(DinigViewModel, FakeRepository)> pumpApp(
    WidgetTester tester,
    CitizenProfile profile,
  ) async {
    SharedPreferences.setMockInitialValues({
      'dinig_citizen_profile': jsonEncode(profile.toJson()),
    });
    tester.view.physicalSize = const Size(1125, 2436);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = FakeRepository();
    final vm = DinigViewModel(repository: repo, notify: (_, _) async {});
    await tester.pumpWidget(MaterialApp(home: DinigMainShell(viewModel: vm)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    return (vm, repo);
  }

  // Long enough to find and reach a target, far short of the auto-advance.
  Future<void> reach(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> close(WidgetTester tester, DinigViewModel vm) async {
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  }

  testWidgets('standard tour pauses the screen, crosses the tabs, and ends on Home',
      (tester) async {
    final (vm, repo) = await pumpApp(tester, resident);
    await tester.tap(find.text('Tour'));
    await reach(tester);
    expect(find.byType(GuideTour), findsOneWidget);
    expect(find.text('DINIG Guide'), findsOneWidget);

    // The SOS button under the tour does nothing.
    await tester.tap(find.text('EMERGENCY SOS'), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(EmergencyDetectedScreen), findsNothing);
    expect(find.textContaining('Paused for the tour'), findsOneWidget);

    Future<void> next() async {
      await tester.tap(find.byTooltip('Next step'));
      await reach(tester);
    }

    for (var i = 0; i < 4; i++) {
      await next(); // SOS, voice, location, phrase
    }
    expect(find.text('EMERGENCY SOS'), findsOneWidget);
    await next();
    expect(find.text('Incident Log'), findsOneWidget);
    await next();
    expect(find.text('Emergency Hotlines'), findsOneWidget);
    await next();
    expect(find.text('Settings'), findsWidgets);

    // Back works across tabs too.
    await tester.tap(find.byTooltip('Previous step'));
    await reach(tester);
    expect(find.text('Emergency Hotlines'), findsOneWidget);
    await next();
    await next();
    expect(find.text('EMERGENCY SOS'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.byType(GuideTour), findsNothing);
    expect(repo.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await close(tester, vm);
  });

  testWidgets('Care Mode tour runs by itself to the end and presses nothing',
      (tester) async {
    final (vm, repo) = await pumpApp(
      tester,
      resident.copyWith(appFor: AppFor.child),
    );
    await tester.tap(find.text('Tour'));
    await reach(tester);
    // Calm: the whole line is there at once, nothing types out.
    expect(find.bySemanticsLabel(RegExp('I am your DINIG guide')), findsOneWidget);

    await tester.tap(find.text('Hurt'), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(EmergencyDetectedScreen), findsNothing);

    // Eight steps, each held at most 9.2 seconds.
    for (var i = 0; i < 80 && find.byType(GuideTour).evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byType(GuideTour), findsNothing);
    expect(find.byType(EmergencyDetectedScreen), findsNothing);
    expect(repo.sent, isEmpty);
    expect(tester.takeException(), isNull);
    await close(tester, vm);
  });

  testWidgets('a heard emergency ends the tour and shows the countdown',
      (tester) async {
    final (vm, _) = await pumpApp(tester, resident);
    await tester.tap(find.text('Tour'));
    await reach(tester);
    expect(find.byType(GuideTour), findsOneWidget);

    vm.heardPhrase('Tulong! May sunog!');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(GuideTour), findsNothing);
    expect(find.byType(EmergencyDetectedScreen), findsOneWidget);

    vm.cancelVerification(); // before the deadline: nothing is sent
    await close(tester, vm);
  });
}
