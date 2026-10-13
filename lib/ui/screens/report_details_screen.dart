import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/incident_models.dart';
import '../theme/dinig_theme.dart';

class ReportDetailsScreen extends StatelessWidget {
  final IncidentReport report;
  final VoidCallback onBack;

  const ReportDetailsScreen({
    super.key,
    required this.report,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');
    final formattedTime = dateFormat.format(report.timestamp);

    return Scaffold(
      backgroundColor: DinigColors.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DinigColors.darkNavy),
          onPressed: onBack,
        ),
        title: const Text(
          'Incident Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: DinigColors.darkNavy,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DinigColors.borderLight),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: DinigColors.softBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            report.id,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: DinigColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(report.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: DinigColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reported $formattedTime',
                    style: const TextStyle(
                      fontSize: 12,
                      color: DinigColors.textSecondary,
                    ),
                  ),
                  if (report.transcript != null &&
                      report.transcript!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DinigColors.bgCanvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DinigColors.borderLight),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.format_quote,
                              color: DinigColors.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"${report.transcript}"',
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: DinigColors.darkNavy,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Where the report says it is from
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DinigColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REGISTERED ADDRESS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: DinigColors.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.locationAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: DinigColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.hasDemoLocation
                        ? 'Coordinates (demo: fixed, not from GPS)'
                        : 'Coordinates (from the phone)',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: DinigColors.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${report.latitude.toStringAsFixed(5)}°N, ${report.longitude.toStringAsFixed(5)}°E',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: DinigColors.darkNavy,
                    ),
                  ),
                ],
              ),
            ),

            if (report.verificationResult != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Phrase check',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: DinigColors.darkNavy,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DinigColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Decision: ${_decisionLabel(report.verificationResult!.recommendedPolicy)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: DinigColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.verificationResult!.reasons,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DinigColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Audio attached to the report
            Text(
              switch (report.audioRecorded) {
                true => 'Audio recording',
                false => 'Placeholder audio tone (not a recording)',
                null => 'Audio attached to this report',
              },
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: DinigColors.darkNavy,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DinigColors.borderLight),
              ),
              child: Text(
                switch (report.audioRecorded) {
                  true =>
                    'A ${report.audioDurationSec} second recording of the sound around the phone during the alert.',
                  false =>
                    'A ${report.audioDurationSec} second tone made by the app. Nothing was recorded.',
                  null =>
                    'Either a recording or a placeholder tone. Reports read back from the server do not say which.',
                },
                style: const TextStyle(
                  fontSize: 12,
                  color: DinigColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _decisionLabel(PolicyAction policy) => switch (policy) {
    PolicyAction.escalate => 'Send now',
    PolicyAction.verify => 'Ask first',
    PolicyAction.suppress => 'No alert',
  };

  Widget _buildStatusBadge(IncidentStatus status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = DinigColors.textSecondary;

    switch (status) {
      case IncidentStatus.detected:
      case IncidentStatus.pendingCancel:
        bg = const Color(0xFFFEF3C7);
        fg = DinigColors.statusAmber;
        break;
      case IncidentStatus.submitted:
      case IncidentStatus.received:
      case IncidentStatus.acknowledged:
        bg = const Color(0xFFDBEAFE);
        fg = DinigColors.primaryBlue;
        break;
      case IncidentStatus.assigned:
      case IncidentStatus.responding:
        bg = const Color(0xFFFEE2E2);
        fg = DinigColors.emergencyRed;
        break;
      case IncidentStatus.resolved:
        bg = const Color(0xFFDCFCE7);
        fg = DinigColors.statusGreen;
        break;
      case IncidentStatus.canceled:
      case IncidentStatus.falseAlarm:
        bg = const Color(0xFFF1F5F9);
        fg = DinigColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
