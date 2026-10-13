import 'package:flutter/material.dart';

import '../components/dial.dart';
import '../theme/dinig_theme.dart';
import '../view_models/dinig_view_model.dart';

class ReportSentScreen extends StatelessWidget {
  final DinigViewModel viewModel;
  final VoidCallback onReturnHome;

  const ReportSentScreen({
    super.key,
    required this.viewModel,
    required this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    final incident = viewModel.activeIncident;
    final state = viewModel.dispatchState;
    final (icon, iconColor, iconBg, title, body) = switch (state) {
      DispatchState.queued => (
        Icons.cloud_off_rounded,
        const Color(0xFFB45309),
        const Color(0xFFFEF3C7),
        'Saved. Will send when online',
        'Your alert is stored on this phone. It is retried automatically while this app is open and the phone is online. If it is urgent, call 911 now.',
      ),
      DispatchState.sent => (
        Icons.check_circle,
        DinigColors.statusGreen,
        const Color(0xFFDCFCE7),
        'Emergency Alert Sent',
        'Your alert was delivered to the DINIG dispatch system.',
      ),
      _ => (
        Icons.hourglass_top_rounded,
        DinigColors.primaryBlue,
        DinigColors.softBlue,
        'Sending your alert…',
        'Contacting the dispatch system. Please keep this screen open.',
      ),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Success Icon
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconBg,
                        ),
                        child: Icon(icon, color: iconColor, size: 56),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: DinigColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: DinigColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (state == DispatchState.sent) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'A dispatcher still has to see it on the dashboard. This app cannot show responder status yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DinigColors.darkNavy,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (state == DispatchState.queued)
                        TextButton(
                          onPressed: () => viewModel.retryPending(force: true),
                          child: const Text('Retry now'),
                        ),

                      const SizedBox(height: 32),

                      // Report Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: DinigColors.bgCanvas,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DinigColors.borderLight),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Report Reference',
                              incident?.id ?? 'Generating…',
                              isBold: true,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Triggered By',
                              incident?.triggerSource ?? 'Preparing…',
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              // A phone position that could be turned into an
                              // address; otherwise the one on the profile.
                              incident != null &&
                                      !incident.hasDemoLocation &&
                                      incident.locationAddress !=
                                          viewModel.userProfile.addressLine
                                  ? 'Address (GPS)'
                                  : 'Registered address',
                              incident?.locationAddress ??
                                  viewModel.userProfile.addressLine,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Coordinates',
                              incident == null || incident.hasDemoLocation
                                  ? 'Demo (fixed, not GPS)'
                                  : '${incident.latitude.toStringAsFixed(4)}, ${incident.longitude.toStringAsFixed(4)}\nfrom this phone, ±${incident.accuracyMeters.toStringAsFixed(0)} m',
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Audio',
                              incident == null
                                  ? 'Preparing…'
                                  : incident.audioRecorded == true
                                  ? 'Recording, ${incident.audioDurationSec} s'
                                  : 'Placeholder tone',
                            ),
                            const Divider(height: 24),
                            _buildDetailRow('Delivery', switch (state) {
                              DispatchState.sent => 'Delivered',
                              DispatchState.queued => 'Queued on this phone',
                              _ => 'Sending…',
                            }),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Emergency Hotline Shortcut Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DinigColors.softBlue,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DinigColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_in_talk,
                              color: DinigColors.primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need immediate phone link?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: DinigColors.primaryBlue,
                                    ),
                                  ),
                                  Text(
                                    'Dial National Emergency 911 directly',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: DinigColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => dialNumber(context, '911'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DinigColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Call 911'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Return Home Secondary Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: onReturnHome,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DinigColors.darkNavy,
                            side: const BorderSide(
                              color: DinigColors.borderLight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text('Return to Home'),
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: DinigColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: DinigColors.darkNavy,
            ),
          ),
        ),
      ],
    );
  }
}
