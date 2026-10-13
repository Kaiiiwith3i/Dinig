import 'package:flutter/material.dart';
import 'data/models/incident_models.dart';
import 'ui/components/dinig_bottom_nav.dart';
import 'ui/components/guide_tour.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/care_home_screen.dart';
import 'ui/screens/emergency_contacts_screen.dart';
import 'ui/screens/emergency_detected_screen.dart';
import 'ui/screens/help_card_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/id_verification_screen.dart';
import 'ui/screens/my_reports_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/report_details_screen.dart';
import 'ui/screens/report_sent_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/welcome_screen.dart';
import 'ui/theme/dinig_theme.dart';
import 'ui/view_models/dinig_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DinigApp());
}

class DinigApp extends StatefulWidget {
  const DinigApp({super.key});

  @override
  State<DinigApp> createState() => _DinigAppState();
}

class _DinigAppState extends State<DinigApp> {
  final DinigViewModel _viewModel = DinigViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DINIG',
      debugShowCheckedModeBanner: false,
      theme: DinigTheme.lightTheme,
      home: DinigMainShell(viewModel: _viewModel),
    );
  }
}

class DinigMainShell extends StatefulWidget {
  final DinigViewModel viewModel;

  const DinigMainShell({super.key, required this.viewModel});

  @override
  State<DinigMainShell> createState() => _DinigMainShellState();
}

/// Every full-screen destination. Exactly one is current, so two screens can
/// never be "showing" at once.
enum _Screen {
  welcome,
  onboarding,
  auth,
  idVerification,
  tabs,
  reportDetails,
  countdown,
  reportSent,
}

class _DinigMainShellState extends State<DinigMainShell>
    with WidgetsBindingObserver {
  _Screen _screen = _Screen.tabs;
  // Where the back gesture on the sign-in screen leads.
  _Screen _authReturn = _Screen.welcome;
  int _currentTab = 0;
  bool _startAuthOnRegister = false;
  bool _booted = false;
  // Care Mode hides the tabs; a caregiver's 3-second hold shows them.
  bool _caregiverMenu = false;
  bool _suppressionDialogOpen = false;
  // The guided tour running over the tabs, or null.
  List<GuideStep>? _tour;
  IncidentReport? _selectedReportForDetails;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A trigger word heard while the app is open brings up the countdown.
    widget.viewModel.onVoiceAlert = () {
      if (mounted) _go(_Screen.countdown);
    };
    widget.viewModel.ready.then((_) {
      if (!mounted) return;
      final profile = widget.viewModel.userProfile;
      setState(() {
        _screen = !profile.isRegistered
            ? _Screen.welcome
            : (profile.isVerified ? _Screen.tabs : _Screen.idVerification);
        _booted = true;
      });
      if (_screen == _Screen.tabs) _askLocation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.viewModel.appForegrounded();
  }

  // Leaving the tabs (an alert starting, most of all) ends a running tour.
  void _go(_Screen screen) => setState(() {
    _screen = screen;
    _tour = null;
  });

  void _goHome() {
    setState(() {
      _screen = _Screen.tabs;
      _currentTab = 0;
    });
    _askLocation();
  }

  // iOS gives no position without this permission. Asked on reaching Home,
  // never during an alert: a dialog over Cancel would be dangerous.
  void _askLocation() => widget.viewModel.refreshLocation(ask: true);

  void _startCountdown() => _go(_Screen.countdown);

  void _openAuth({required bool register}) => setState(() {
    _authReturn = _screen;
    _startAuthOnRegister = register;
    _screen = _Screen.auth;
  });

  // Every step names its tab, so Back works across tabs as well as Next.
  GuideStep _tabStep(int tab, GlobalKey target, String text) =>
      GuideStep(target, text, before: () => setState(() => _currentTab = tab));

  /// Standard mode tours the whole app. Care Mode tours the picture buttons,
  /// or the caregiver's menu while that is showing.
  void _startTour() {
    final tabs = [
      _tabStep(
        1,
        GuideKeys.reports,
        'Reports lists the reports sent from this phone number.',
      ),
      _tabStep(
        2,
        GuideKeys.hotlines,
        'Hotlines has your emergency contact and 911, ready to call.',
      ),
      _tabStep(
        3,
        GuideKeys.settings,
        'Settings has your profile and what is still a prototype.',
      ),
    ];
    final List<GuideStep> steps;
    if (!widget.viewModel.userProfile.appFor.isCareMode) {
      steps = [
        _tabStep(
          0,
          GuideKeys.title,
          "Hi, I'm your DINIG guide. Let me show you around.",
        ),
        _tabStep(
          0,
          GuideKeys.sos,
          'This is SOS. Press it to start a 5 second countdown. Cancel before it ends and nothing is sent.',
        ),
        _tabStep(
          0,
          GuideKeys.voice,
          'Turn this on and the phone listens for Help, Tulong or Saklolo while DINIG is open.',
        ),
        _tabStep(
          0,
          GuideKeys.location,
          'This is the location a report carries. It says so when it is only a demo location.',
        ),
        _tabStep(
          0,
          GuideKeys.phrase,
          'Type a phrase here to see what the phone decides: send now, ask first, or no alert.',
        ),
        ...tabs,
        _tabStep(
          0,
          GuideKeys.tour,
          "That's the tour. Tap Tour to see it again. Stay safe.",
        ),
      ];
    } else if (_caregiverMenu) {
      steps = [
        _tabStep(
          0,
          GuideKeys.hold,
          'This is the caregiver menu. Hold the DINIG title for 3 seconds to hide it again.',
        ),
        ...tabs,
        _tabStep(
          0,
          GuideKeys.tour,
          "That's the tour. With the menu hidden, Tour explains the picture buttons instead.",
        ),
      ];
    } else {
      steps = [
        GuideStep(
          GuideKeys.title,
          'Hi. I am your DINIG guide. I will show you the buttons.',
        ),
        GuideStep(
          GuideKeys.care[CareNeed.hurt.index],
          'Tap Hurt if you are hurt. It tells the barangay after a countdown.',
        ),
        GuideStep(
          GuideKeys.care[CareNeed.fire.index],
          'Tap Fire if there is a fire. It tells the barangay after a countdown.',
        ),
        GuideStep(
          GuideKeys.care[CareNeed.lost.index],
          'Tap Lost if you are lost. It tells the barangay after a countdown.',
        ),
        GuideStep(
          GuideKeys.care[CareNeed.scared.index],
          'Tap Scared to make a phone call. It does not send a report.',
        ),
        GuideStep(
          GuideKeys.care[CareNeed.grownUp.index],
          'Tap Need a grown-up to make a phone call. It does not send a report.',
        ),
        GuideStep(GuideKeys.call911, 'This button calls 911.'),
        GuideStep(GuideKeys.tour, 'That is all. Tap Tour to watch this again.'),
      ];
    }
    setState(() => _tour = steps);
  }

  /// The screen the back gesture returns to, or null when there is none.
  /// The countdown and result screens have none on purpose: an alert is left
  /// only through its own Cancel or Return buttons.
  _Screen? _backOf(_Screen screen) => switch (screen) {
    _Screen.onboarding => _Screen.welcome,
    _Screen.auth => _authReturn,
    _Screen.reportDetails => _Screen.tabs,
    _ => null,
  };

  /// The phrase check said "no alert". Shown once per result, with a way to
  /// send anyway so a real emergency is never a dead end.
  void _showSuppressionDialog() {
    final vm = widget.viewModel;
    final res = vm.suppressionDialogResult;
    if (!mounted || res == null || _suppressionDialogOpen) return;
    _suppressionDialogOpen = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No alert sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phrase: "${res.transcript}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              res.reasons,
              style: const TextStyle(color: DinigColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text('If this is a real emergency, send it anyway.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              vm.sendSuppressedAnyway(onNavigateToEmergency: _startCountdown);
            },
            child: const Text('Send anyway'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK, no alert'),
          ),
        ],
      ),
    ).then((_) {
      _suppressionDialogOpen = false;
      vm.dismissSuppressionDialog();
    });
  }

  /// Care Mode: the caregiver's 3-second hold on the title shows or hides the
  /// tabs. Confirmed first, so a child's accidental hold changes nothing.
  Future<void> _toggleCaregiverMenu() async {
    final showing = _caregiverMenu;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(showing ? 'Hide the full menu?' : 'For the caregiver'),
        content: Text(
          showing
              ? 'The picture buttons stay. The tabs at the bottom are hidden again.'
              : 'Show the full menu (reports, contacts, settings) on this phone?',
        ),
        actions: [
          // Behind the same 3-second hold, so a child's tap cannot reach it.
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _logOut();
            },
            child: const Text('Log out'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(showing ? 'Hide menu' : 'Show menu'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        _caregiverMenu = !showing;
        _currentTab = 0;
      });
    }
  }

  /// Confirmed first: after this the phone has no profile to report with.
  Future<void> _logOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Your details are removed from this phone. DINIG cannot send a report from it until someone registers or signs in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.viewModel.logout();
    if (!mounted) return;
    setState(() {
      _screen = _Screen.welcome;
      _caregiverMenu = false;
      _currentTab = 0;
      _tour = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    if (!_booted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.suppressionDialogResult != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _showSuppressionDialog(),
          );
        }

        // The current screen on top of the screens "back" leads to, so the
        // system back gesture pops one page.
        final stack = [_screen];
        for (var b = _backOf(_screen); b != null; b = _backOf(b)) {
          stack.insert(0, b);
        }

        // NavigatorPopHandler routes the system back button to this
        // navigator (the iOS edge swipe reaches it directly).
        final navigator = NavigatorPopHandler<Object?>(
          onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
          child: Navigator(
            key: _navigatorKey,
            pages: [
              for (final screen in stack)
                MaterialPage(
                  key: ValueKey(screen),
                  child: _buildScreen(screen, vm),
                ),
            ],
            onDidRemovePage: (page) {
              // Only a back gesture on the top page changes the screen; pages
              // dropped because _screen already changed need nothing.
              final back = _backOf(_screen);
              if (page.key == ValueKey(_screen) && back != null) _go(back);
            },
          ),
        );

        final tour = _tour;
        final pictureScreen =
            vm.userProfile.appFor.isCareMode && !_caregiverMenu;
        return Stack(
          fit: StackFit.expand,
          children: [
            navigator,
            if (tour != null)
              GuideTour(
                steps: tour,
                calm: pictureScreen,
                // Keeps the tour's controls above the tab bar.
                bottomInset: pictureScreen ? 0 : 56,
                onDone: () => setState(() {
                  _tour = null;
                  _currentTab = 0;
                }),
              ),
          ],
        );
      },
    );
  }

  Widget _buildScreen(_Screen screen, DinigViewModel vm) {
    final isCareMode = vm.userProfile.appFor.isCareMode;

    switch (screen) {
      case _Screen.welcome:
        return WelcomeScreen(
          onGetStarted: () => _go(_Screen.onboarding),
          onSignIn: () => _openAuth(register: false),
        );

      case _Screen.onboarding:
        return OnboardingScreen(onContinue: () => _openAuth(register: true));

      case _Screen.auth:
        return AuthScreen(
          viewModel: vm,
          startOnRegister: _startAuthOnRegister,
          onAuthenticated: () => vm.userProfile.isVerified
              ? _goHome()
              : _go(_Screen.idVerification),
          onSignedUp: () => _go(_Screen.idVerification),
        );

      case _Screen.idVerification:
        return IdVerificationScreen(
          viewModel: vm,
          onVerificationComplete: () {
            vm.saveUserProfile(vm.userProfile.copyWith(isVerified: true));
            _goHome();
          },
        );

      case _Screen.reportDetails:
        return ReportDetailsScreen(
          report: _selectedReportForDetails!,
          onBack: () => _go(_Screen.tabs),
        );

      case _Screen.countdown:
        return EmergencyDetectedScreen(
          viewModel: vm,
          onCancel: () => _go(_Screen.tabs),
          // The countdown screen reports this more than once; only the first
          // call, made while it is still current, moves on.
          onReportSent: () {
            if (_screen == _Screen.countdown) _go(_Screen.reportSent);
          },
        );

      case _Screen.reportSent:
        // Care Mode ends on the Help Card, not the adult report screen.
        return isCareMode
            ? HelpCardScreen(
                profile: vm.userProfile,
                dispatchState: vm.dispatchState,
                onRetry: () => vm.retryPending(force: true),
                onDone: _goHome,
              )
            : ReportSentScreen(viewModel: vm, onReturnHome: _goHome);

      case _Screen.tabs:
        final body = switch (_currentTab) {
          1 => MyReportsScreen(
            viewModel: vm,
            onSelectReport: (report) => setState(() {
              _selectedReportForDetails = report;
              _screen = _Screen.reportDetails;
            }),
          ),
          2 => EmergencyContactsScreen(viewModel: vm),
          3 => SettingsScreen(
            viewModel: vm,
            onSwitchAccount: () => _openAuth(register: false),
            onLogout: _logOut,
          ),
          _ when isCareMode => CareHomeScreen(
            viewModel: vm,
            onTriggerEmergency: _startCountdown,
            onCaregiverHold: _toggleCaregiverMenu,
            onStartTour: _startTour,
          ),
          _ => HomeScreen(
            viewModel: vm,
            onTriggerEmergency: _startCountdown,
            onStartTour: _startTour,
          ),
        };

        return Scaffold(
          body: body,
          bottomNavigationBar: isCareMode && !_caregiverMenu
              ? null
              : DinigBottomNav(
                  currentIndex: _currentTab,
                  onTabSelected: (index) => setState(() => _currentTab = index),
                ),
        );
    }
  }
}
