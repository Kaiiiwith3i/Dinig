import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../components/dial.dart';
import '../components/guide_tour.dart';
import '../theme/dinig_theme.dart';
import '../view_models/dinig_view_model.dart';

/// Home for Care Mode: big picture buttons, no typing or speaking needed.
/// Every button prints what it will do. Hurt, Fire and Lost report to the
/// barangay after a cancel countdown; Scared and Need a grown-up only call.
class CareHomeScreen extends StatelessWidget {
  final DinigViewModel viewModel;
  final VoidCallback onTriggerEmergency;
  final VoidCallback onCaregiverHold;
  final VoidCallback? onStartTour;

  const CareHomeScreen({
    super.key,
    required this.viewModel,
    required this.onTriggerEmergency,
    required this.onCaregiverHold,
    this.onStartTour,
  });

  static const _icons = {
    CareNeed.hurt: Icons.healing,
    CareNeed.lost: Icons.wrong_location_outlined,
    CareNeed.scared: Icons.sentiment_very_dissatisfied,
    CareNeed.fire: Icons.local_fire_department,
    CareNeed.grownUp: Icons.family_restroom,
  };

  @override
  Widget build(BuildContext context) {
    final profile = viewModel.userProfile;
    final phone = profile.emergencyContactPhone.trim();
    final name = profile.emergencyContactName.trim();
    final callCaption = phone.isEmpty
        ? 'Calls 911'
        : (name.isEmpty ? 'Calls your caregiver' : 'Calls $name');

    return Scaffold(
      appBar: AppBar(
        // Hold the title for 3 s to leave the picture screen. A tap does nothing.
        title: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: const Duration(seconds: 3),
              ),
              (r) => r.onLongPress = onCaregiverHold,
            ),
          },
          child: Padding(
            key: GuideKeys.hold,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Text('DINIG'),
          ),
        ),
        actions: [
          if (onStartTour != null)
            TextButton.icon(
              key: GuideKeys.tour,
              onPressed: onStartTour,
              icon: const Icon(Icons.explore_outlined, size: 20),
              label: const Text('Tour'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'What do you need?',
            key: GuideKeys.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: DinigColors.darkNavy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap one picture. Under each name it says what happens.',
            style: TextStyle(fontSize: 16, color: DinigColors.textSecondary),
          ),
          const SizedBox(height: 16),
          for (final need in CareNeed.values) ...[
            _NeedButton(
              key: GuideKeys.care[need.index],
              label: need.label,
              phrase: need.phrase,
              caption: need.callsCaregiver
                  ? callCaption
                  : (need == CareNeed.lost
                      ? 'Tells the barangay you are lost'
                      : 'Tells the barangay'),
              icon: _icons[need]!,
              calls: need.callsCaregiver,
              onTap: need.callsCaregiver
                  ? () => dialNumber(context, phone.isEmpty ? '911' : phone)
                  : () => viewModel.triggerCareSos(
                        need,
                        onNavigateToEmergency: onTriggerEmergency,
                      ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          SizedBox(
            key: GuideKeys.call911,
            height: 64,
            child: ElevatedButton.icon(
              onPressed: () => dialNumber(context, '911'),
              icon: const Icon(Icons.call, size: 28),
              label: const Text(
                'CALL 911',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DinigColors.emergencyRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Caregiver: press and hold the DINIG title for 3 seconds for the full menu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: DinigColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// A full-width picture button. Report buttons are filled blue; call buttons
/// are white with a border and a phone badge, so the difference is not color only.
class _NeedButton extends StatelessWidget {
  final String label;
  final String phrase;
  final String caption;
  final IconData icon;
  final bool calls;
  final VoidCallback onTap;

  const _NeedButton({
    super.key,
    required this.label,
    required this.phrase,
    required this.caption,
    required this.icon,
    required this.calls,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$phrase. $caption',
      excludeSemantics: true,
      child: Material(
        color: calls ? DinigColors.cardSurface : DinigColors.softBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: calls ? DinigColors.primaryBlue : DinigColors.borderLight,
            width: calls ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(icon, size: 56, color: DinigColors.primaryBlue),
                        if (calls)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: DinigColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.call, size: 18, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: DinigColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          caption,
                          style: const TextStyle(
                            fontSize: 16,
                            color: DinigColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
