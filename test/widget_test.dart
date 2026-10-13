import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dinig/data/models/citizen_profile.dart';
import 'package:dinig/main.dart';
import 'package:dinig/ui/components/dinig_bottom_nav.dart';
import 'package:dinig/ui/screens/emergency_detected_screen.dart';
import 'package:dinig/ui/screens/id_verification_screen.dart';
import 'package:dinig/ui/view_models/dinig_view_model.dart';

void main() {
  testWidgets('Fresh install opens Welcome, not the dashboard',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const DinigApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('DINIG'), findsOneWidget);
    expect(find.text('GET STARTED'), findsOneWidget);
    expect(find.text('EMERGENCY SOS'), findsNothing);
  });

  testWidgets('KYC mock: double taps do not skip steps; completes once',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1125, 2436); // 375x812 @3x
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: IdVerificationScreen(
        viewModel: DinigViewModel(),
        onVerificationComplete: () => completed++,
      ),
    ));

    Future<void> tapText(String label, {int times = 1}) async {
      final f = find.text(label);
      await tester.ensureVisible(f);
      for (var i = 0; i < times; i++) {
        await tester.tap(f);
      }
    }

    await tapText('Next');
    await tester.pump();
    // Double-tap on the front-of-ID capture must advance exactly one step.
    await tapText('Take Photo', times: 2);
    await tester.pump(const Duration(seconds: 1));
    await tapText('Take Photo', times: 2);
    await tester.pump(const Duration(seconds: 1));

    await tapText('Take Selfie');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Detecting face…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('GO TO DASHBOARD'), findsOneWidget);
    await tester.tap(find.text('GO TO DASHBOARD'));
    await tester.pump();
    expect(completed, 1);
  });

  // Opens the app past registration with [profile] already stored.
  Future<void> pumpHome(WidgetTester tester, CitizenProfile profile) async {
    SharedPreferences.setMockInitialValues({
      'dinig_citizen_profile': jsonEncode(profile.toJson()),
    });
    tester.view.physicalSize = const Size(1125, 2436); // 375x812 @3x
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DinigApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  const resident = CitizenProfile(
    fullName: 'Test Resident',
    phoneNumber: '0000',
    barangay: 'Brgy. Test',
    isRegistered: true,
    isLoggedIn: true,
    isVerified: true,
  );

  testWidgets('standard mode shows the tabs', (tester) async {
    await pumpHome(tester, resident);
    expect(find.text('EMERGENCY SOS'), findsOneWidget);
    expect(find.byType(DinigBottomNav), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Care Mode hides the tabs until the caregiver holds the title',
      (tester) async {
    await pumpHome(tester, resident.copyWith(appFor: AppFor.child));
    expect(find.text('Hurt'), findsOneWidget);
    expect(find.byType(DinigBottomNav), findsNothing);

    final hold = await tester.startGesture(tester.getCenter(find.text('DINIG')));
    await tester.pump(const Duration(milliseconds: 3100));
    await hold.up();
    await tester.pump();
    expect(find.text('For the caregiver'), findsOneWidget);
    expect(find.byType(DinigBottomNav), findsNothing);

    await tester.tap(find.text('Show menu'));
    await tester.pumpAndSettle();
    expect(find.byType(DinigBottomNav), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a "no alert" phrase offers Send anyway and it starts the countdown',
      (tester) async {
    await pumpHome(tester, resident);
    await tester.enterText(
      find.byType(TextField),
      'Help naman sa assignment namin sa math',
    );
    await tester.ensureVisible(find.text('Check phrase'));
    await tester.tap(find.text('Check phrase'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No alert sent'), findsOneWidget);
    expect(find.byType(EmergencyDetectedScreen), findsNothing);

    await tester.tap(find.text('Send anyway'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EmergencyDetectedScreen), findsOneWidget);

    // Unmount before the 5 s deadline so nothing is dispatched.
    await tester.pumpWidget(const SizedBox());
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('back button: onboarding returns to Welcome', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DinigApp());
    await settle(tester);

    await tester.tap(find.text('GET STARTED'));
    await settle(tester);
    expect(find.text('Continue'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('GET STARTED'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets(
    'iOS edge swipe: onboarding returns to Welcome and state follows',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const DinigApp());
      await settle(tester);
      await tester.tap(find.text('GET STARTED'));
      await settle(tester);

      await tester.dragFrom(const Offset(5, 300), const Offset(500, 0));
      await settle(tester);
      expect(find.text('GET STARTED'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);

      // The screen state followed the gesture: forward works again.
      await tester.tap(find.text('GET STARTED'));
      await settle(tester);
      expect(find.text('Continue'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('the countdown cannot be left with back, only with Cancel',
      (tester) async {
    await pumpHome(tester, resident);
    await tester.tap(find.text('EMERGENCY SOS'));
    await settle(tester);
    expect(find.byType(EmergencyDetectedScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(EmergencyDetectedScreen), findsOneWidget);

    // Unmount before the 5 s deadline so nothing is dispatched.
    await tester.pumpWidget(const SizedBox());
  });

  // In widget tests every request fails, which is the "no internet" path.
  testWidgets('offline SOS ends on "Saved", never "Sent", then returns home',
      (tester) async {
    await pumpHome(tester, resident);
    await tester.tap(find.text('EMERGENCY SOS'));
    await settle(tester);
    await tester.tap(find.text('SEND IMMEDIATELY'));
    for (var i = 0; i < 4; i++) {
      await settle(tester);
    }

    expect(find.text('Saved. Will send when online'), findsOneWidget);
    expect(find.text('Emergency Alert Sent'), findsNothing);

    await tester.ensureVisible(find.text('Return to Home'));
    await tester.tap(find.text('Return to Home'));
    await settle(tester);
    expect(find.text('EMERGENCY SOS'), findsOneWidget);
    expect(find.textContaining('saved on this phone'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('offline Care Mode report ends on the Help Card as "Saved"',
      (tester) async {
    await pumpHome(
      tester,
      resident.copyWith(
        appFor: AppFor.child,
        emergencyContactName: 'Test Caregiver',
        emergencyContactPhone: '0000',
        supportNotes: 'Does not speak; Ask before touching',
      ),
    );
    await tester.tap(find.text('Hurt'));
    await settle(tester);
    await tester.tap(find.text('SEND HELP NOW'));
    for (var i = 0; i < 4; i++) {
      await settle(tester);
    }

    expect(find.text('Show this to the helper'), findsOneWidget);
    expect(find.text('Saved on this phone'), findsOneWidget);
    expect(find.text('Alert sent'), findsNothing);
    expect(find.text('Does not speak'), findsOneWidget);
    expect(find.byType(DinigBottomNav), findsNothing);

    await tester.scrollUntilVisible(find.text('Back to pictures'), 200);
    await tester.tap(find.text('Back to pictures'));
    await settle(tester);
    expect(find.text('Hurt'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
