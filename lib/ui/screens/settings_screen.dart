import 'package:flutter/material.dart';
import '../components/guide_tour.dart';
import '../theme/dinig_theme.dart';
import '../view_models/dinig_view_model.dart';

class SettingsScreen extends StatelessWidget {
  final DinigViewModel viewModel;
  final VoidCallback onSwitchAccount;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.viewModel,
    required this.onSwitchAccount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final profile = viewModel.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Citizen Profile Card
          Card(
            key: GuideKeys.settings,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: DinigColors.primaryBlue,
                    child: Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: DinigColors.darkNavy,
                          ),
                        ),
                        Text(
                          profile.addressLine,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DinigColors.textSecondary,
                          ),
                        ),
                        Text(
                          profile.phoneNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DinigColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onSwitchAccount,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      side: const BorderSide(color: DinigColors.borderLight),
                    ),
                    child: const Text('Switch', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'PROTOTYPE STATUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: DinigColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Until you allow them, location is a fixed demo coordinate and report audio is a placeholder tone. The ID check is a demo.\n'
                'New and still being tested: the voice trigger, phone location and audio recording. Not built yet: responder status.',
                style: TextStyle(
                  fontSize: 13,
                  color: DinigColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: DinigColors.emergencyRed,
              side: const BorderSide(color: DinigColors.borderLight),
            ),
          ),
        ],
      ),
    );
  }
}
