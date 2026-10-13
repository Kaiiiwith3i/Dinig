import 'package:flutter/material.dart';

import '../../data/models/incident_models.dart';
import '../components/breathing_guide.dart';
import '../components/emergency_pulse.dart';
import '../theme/dinig_theme.dart';
import '../view_models/dinig_view_model.dart';

class EmergencyDetectedScreen extends StatelessWidget {
  final DinigViewModel viewModel;
  final VoidCallback onCancel;
  final VoidCallback onReportSent;

  const EmergencyDetectedScreen({
    super.key,
    required this.viewModel,
    required this.onCancel,
    required this.onReportSent,
  });

  @override
  Widget build(BuildContext context) {
    final verification = viewModel.activeVerificationResult;
    final countdown = viewModel.countdownSecondsRemaining;
    final isCare = viewModel.userProfile.appFor.isCareMode;

    // The countdown ended (or send-now was tapped): show the delivery result.
    if (viewModel.dispatchState != DispatchState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onReportSent();
      });
    }

    final isManual = verification?.detectedKeyword.contains('Manual') ?? false;
    final decision =
        verification?.recommendedPolicy == PolicyAction.verify
        ? 'Ask first'
        : 'Send now';
    final location = viewModel.currentLocation;

    return Scaffold(
      backgroundColor: DinigColors.emergencyDarkBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // Header
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DinigColors.emergencyRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            verification?.riskLevel ?? 'HIGH RISK',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Countdown Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const EmergencyPulse(size: 160),
                          Text(
                            '$countdown',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Sending in $countdown s unless you cancel',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCare
                            ? (verification?.transcript.replaceFirst(
                                    'Care Mode: ',
                                    '',
                                  ) ??
                                  '')
                            : isManual
                            ? 'Manual SOS'
                            : '${viewModel.alertFromVoice ? 'Heard' : 'Phrase'}: "${verification?.transcript ?? ''}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Care Mode shows a breathing guide instead of the mechanism
                      isCare
                          ? const BreathingGuide()
                          : Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0x33FFFFFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Decision: $decision',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    verification?.reasons ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'When the countdown ends, this phone sends:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  for (final line in [
                                    'Your name and phone number',
                                    if (viewModel.resolvedAddress != null)
                                      'The address at your location'
                                    else
                                      'Your registered address',
                                    if (location.isLive)
                                      'Your location from this phone (${location.formattedAccuracy})'
                                    else
                                      'A demo location (fixed coordinate, not GPS)',
                                    if (viewModel.recordingEvidence)
                                      'A recording of the sound around this phone, being made now'
                                    else
                                      'A placeholder audio tone (no recording is made)',
                                  ])
                                    Text(
                                      '• $line',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                      const Spacer(flex: 1),

                      // Send now: secondary, smaller
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            viewModel.confirmDispatchNow();
                            onReportSent();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            isCare ? 'SEND HELP NOW' : 'SEND IMMEDIATELY',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cancel: the largest and nearest control
                      SizedBox(
                        width: double.infinity,
                        height: 72,
                        child: ElevatedButton(
                          onPressed: () {
                            viewModel.cancelVerification();
                            onCancel();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: DinigColors.emergencyDarkBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(36),
                            ),
                          ),
                          child: Text(
                            isCare ? 'I AM OKAY' : 'CANCEL (FALSE ALARM)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
