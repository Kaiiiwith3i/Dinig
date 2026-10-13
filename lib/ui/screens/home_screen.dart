import 'package:flutter/material.dart';
import '../components/dinig_logo.dart';
import '../components/guide_tour.dart';
import '../theme/dinig_theme.dart';
import '../view_models/dinig_view_model.dart';

class HomeScreen extends StatefulWidget {
  final DinigViewModel viewModel;
  final VoidCallback onTriggerEmergency;
  final VoidCallback? onStartTour;

  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.onTriggerEmergency,
    this.onStartTour,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _phraseController = TextEditingController();

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  void _checkPhrase(String phrase) => widget.viewModel.checkPhrase(
    phrase,
    onNavigateToEmergency: widget.onTriggerEmergency,
  );

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final pending = viewModel.pendingReports;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          key: GuideKeys.title,
          mainAxisSize: MainAxisSize.min,
          children: [
            const DinigLogo(size: 32),
            const SizedBox(width: 8),
            const Text(
              'DINIG',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: DinigColors.darkNavy,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onStartTour != null)
            TextButton.icon(
              key: GuideKeys.tour,
              onPressed: widget.onStartTour,
              icon: const Icon(Icons.explore_outlined, size: 20),
              label: const Text('Tour'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Giant Manual Emergency SOS Button
            SizedBox(
              key: GuideKeys.sos,
              width: double.infinity,
              height: 72,
              child: ElevatedButton.icon(
                onPressed: () {
                  viewModel.triggerManualSos(
                    onNavigateToEmergency: widget.onTriggerEmergency,
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 28),
                label: const Text(
                  'EMERGENCY SOS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DinigColors.emergencyRed,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: const Color(0x66DC2626),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(36),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Voice trigger: real listening through the phone's speech engine
            Container(
              key: GuideKeys.voice,
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DinigColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        viewModel.listeningOn ? Icons.mic : Icons.mic_off,
                        color: viewModel.listeningOn
                            ? DinigColors.primaryBlue
                            : DinigColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'VOICE TRIGGER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: DinigColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: viewModel.listeningOn,
                        onChanged: viewModel.setListening,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      viewModel.listeningProblem ??
                          (viewModel.listeningOn
                              ? 'Listening for Help, Tulong or Saklolo while DINIG is open. iOS stops speech recognition soon after the app leaves the screen; DINIG notifies you and resumes when you open it again.'
                              : 'Off. Turn on to let this phone hear Help, Tulong or Saklolo and start a report.'),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: viewModel.listeningProblem != null
                            ? DinigColors.emergencyRed
                            : DinigColors.textSecondary,
                      ),
                    ),
                  ),
                  if (viewModel.lastHeard != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: Text(
                        'Last heard: ${viewModel.lastHeard}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DinigColors.darkNavy,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (pending > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$pending ${pending == 1 ? 'report' : 'reports'} saved on this phone, waiting to send.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => viewModel.retryPending(force: true),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                      child: const Text('Retry now'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Location card
            Container(
              key: GuideKeys.location,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DinigColors.borderLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: DinigColors.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viewModel.currentLocation.isLive
                              ? 'YOUR LOCATION'
                              : 'DEMO LOCATION',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: DinigColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          viewModel.currentLocation.formattedCoordinates,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: DinigColors.darkNavy,
                          ),
                        ),
                        Text(
                          viewModel.currentLocation.isLive
                              ? [
                                  'From this phone\'s location, ${viewModel.currentLocation.formattedAccuracy}.',
                                  ?viewModel.resolvedAddress,
                                ].join(' ')
                              : viewModel.locationAllowed
                              ? 'Fixed coordinate, not where you are. This phone has not given a position yet.'
                              : 'Fixed coordinate, not where you are. Location is off for DINIG.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: DinigColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          viewModel.recordingAllowed
                              ? 'A report carries a recording of the sound around you.'
                              : 'A report carries a placeholder tone, not a recording.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: DinigColors.textSecondary,
                          ),
                        ),
                        if (!viewModel.currentLocation.isLive ||
                            !viewModel.recordingAllowed)
                          // Outlined: with a navy tint, a bare text button
                          // would read as a line of text.
                          OutlinedButton(
                            onPressed: viewModel.requestPermissions,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 44),
                            ),
                            child: const Text('Allow location and recording'),
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'Registered address',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: DinigColors.textSecondary,
                          ),
                        ),
                        Text(
                          viewModel.userProfile.addressLine,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DinigColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Typed-phrase check: the entry point voice input will feed later.
            Container(
              key: GuideKeys.phrase,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DinigColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRY A PHRASE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: DinigColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Type what someone might say. The phone checks it with on-device rules and decides: send now, ask first, or no alert. A phrase heard by the voice trigger goes through the same check.',
                    style: TextStyle(
                      fontSize: 12,
                      color: DinigColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phraseController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _checkPhrase,
                    decoration: InputDecoration(
                      hintText: 'Tulong! May sunog sa kusina',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _checkPhrase(_phraseController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DinigColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Check phrase',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Or tap an example',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: DinigColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildScenarioRow(
                    title: '🚨 "Tulong! May humahabol sa akin!"',
                    subtitle: 'Send now: 5 second countdown',
                    phrase: 'Tulong! May humahabol sa akin!',
                  ),
                  const Divider(height: 8),
                  _buildScenarioRow(
                    title: '🛡️ "Help naman sa assignment namin sa math"',
                    subtitle: 'No alert: study words found',
                    phrase: 'Help naman sa assignment namin sa math',
                  ),
                  const Divider(height: 8),
                  _buildScenarioRow(
                    title: '🛡️ "Joke lang, nagbibiro lang kami haha"',
                    subtitle: 'No alert: joke words found',
                    phrase: 'Joke lang, nagbibiro lang kami haha',
                  ),
                  const Divider(height: 8),
                  _buildScenarioRow(
                    title: '⚠️ "Help please..."',
                    subtitle: 'Ask first: 10 second countdown',
                    phrase: 'Help please...',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioRow({
    required String title,
    required String subtitle,
    required String phrase,
  }) {
    return InkWell(
      onTap: () => _checkPhrase(phrase),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: DinigColors.darkNavy,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: DinigColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.play_circle_fill,
              color: DinigColors.primaryBlue,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
