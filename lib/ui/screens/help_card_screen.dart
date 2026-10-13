import 'package:flutter/material.dart';
import '../../data/models/citizen_profile.dart';
import '../components/dial.dart';
import '../theme/dinig_theme.dart';
import '../view_models/dinig_view_model.dart';

/// What a helper needs to know about the person, built from the profile.
class HelpCard extends StatelessWidget {
  final CitizenProfile profile;

  const HelpCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final support = profile.supportNotes.trim().isEmpty
        ? const <String>[]
        : profile.supportNotes.split('; ').where((s) => s.isNotEmpty).toList();
    final medical = profile.medicalNotes.trim();
    final name = profile.fullName.trim();
    final caregiverName = profile.emergencyContactName.trim();
    final caregiverPhone = profile.emergencyContactPhone.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DinigColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DinigColors.primaryBlue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'Name not entered yet' : name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: DinigColors.darkNavy,
            ),
          ),
          if (support.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _CardLabel('How to help'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final s in support) _SupportLine(s)],
            ),
          ],
          if (medical.isNotEmpty && medical != 'None') ...[
            const SizedBox(height: 14),
            const _CardLabel('Medical notes'),
            const SizedBox(height: 4),
            Text(
              medical,
              style: const TextStyle(
                fontSize: 20,
                color: DinigColors.textPrimary,
              ),
            ),
          ],
          if (caregiverName.isNotEmpty || caregiverPhone.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _CardLabel('Caregiver'),
            const SizedBox(height: 4),
            if (caregiverName.isNotEmpty)
              Text(
                caregiverName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: DinigColors.textPrimary,
                ),
              ),
            if (caregiverPhone.isNotEmpty)
              Text(
                caregiverPhone,
                style: const TextStyle(
                  fontSize: 22,
                  color: DinigColors.textPrimary,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  final String text;
  const _CardLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      color: DinigColors.textSecondary,
    ),
  );
}

class _SupportLine extends StatelessWidget {
  final String text;
  const _SupportLine(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: DinigColors.lightBlue,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: DinigColors.darkNavy,
      ),
    ),
  );
}

/// Care Mode's version of Report Sent. Pure widget of its parameters: the
/// delivery wording is driven only by [dispatchState].
class HelpCardScreen extends StatelessWidget {
  final CitizenProfile profile;
  final DispatchState dispatchState;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  const HelpCardScreen({
    super.key,
    required this.profile,
    required this.dispatchState,
    required this.onRetry,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final phone = profile.emergencyContactPhone.trim();
    final name = profile.emergencyContactName.trim();
    final callLabel = phone.isEmpty
        ? 'Call 911'
        : (name.isEmpty ? 'Call your caregiver' : 'Call $name');

    return Scaffold(
      appBar: AppBar(title: const Text('DINIG')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DeliveryStatus(state: dispatchState, onRetry: onRetry),
            const SizedBox(height: 20),
            const Text(
              'Show this to the helper',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: DinigColors.darkNavy,
              ),
            ),
            const SizedBox(height: 10),
            HelpCard(profile: profile),
            const SizedBox(height: 10),
            const Text(
              'This card is shown on this phone. It was not sent with the alert.',
              style: TextStyle(fontSize: 16, color: DinigColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    dialNumber(context, phone.isEmpty ? '911' : phone),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(72),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  backgroundColor: DinigColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(36),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.call, size: 28),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        callLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDone,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  foregroundColor: DinigColors.darkNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: const Text(
                  'Back to pictures',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryStatus extends StatelessWidget {
  final DispatchState state;
  final VoidCallback onRetry;

  const _DeliveryStatus({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final (
      IconData icon,
      Color color,
      String title,
      String? body,
    ) = switch (state) {
      DispatchState.sent => (
        Icons.check_circle,
        DinigColors.statusGreen,
        'Alert sent',
        'The alert reached the DINIG dispatch system.',
      ),
      DispatchState.queued => (
        Icons.save_alt,
        DinigColors.statusAmber,
        'Saved on this phone',
        'It will send when this phone is online and this app is open. If it is urgent, call 911.',
      ),
      _ => (
        Icons.hourglass_top,
        DinigColors.primaryBlue,
        'Sending your alert…',
        null,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: DinigColors.darkNavy,
                  ),
                ),
              ),
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 18,
                color: DinigColors.textPrimary,
              ),
            ),
          ],
          if (state == DispatchState.queued) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: DinigColors.darkNavy,
                ),
                child: const Text(
                  'Retry now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
