import 'package:flutter/material.dart';
import '../components/dial.dart';
import '../components/guide_tour.dart';
import '../theme/dinig_theme.dart';
import '../view_models/dinig_view_model.dart';

class EmergencyContactsScreen extends StatelessWidget {
  final DinigViewModel viewModel;

  const EmergencyContactsScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Hotlines'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Personal emergency contact card
          Card(
            key: GuideKeys.hotlines,
            color: DinigColors.softBlue,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: DinigColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR DESIGNATED EMERGENCY CONTACT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: DinigColors.primaryBlue,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          viewModel.userProfile.emergencyContactName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: DinigColors.darkNavy,
                          ),
                        ),
                        Text(
                          viewModel.userProfile.emergencyContactPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: DinigColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: viewModel.userProfile.emergencyContactPhone.isEmpty
                        ? null
                        : () => dialNumber(context,
                            viewModel.userProfile.emergencyContactPhone),
                    icon: const Icon(Icons.phone, color: DinigColors.primaryBlue),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'PHILIPPINE PUBLIC SAFETY HOTLINES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: DinigColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DinigColors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emergency, color: DinigColors.primaryBlue),
              ),
              title: const Text(
                'National Emergency Hotline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: DinigColors.darkNavy,
                ),
              ),
              subtitle: const Text(
                '911 • Police, Fire, Medical, Rescue',
                style: TextStyle(
                  fontSize: 12,
                  color: DinigColors.textSecondary,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.call, color: DinigColors.statusGreen),
                onPressed: () => dialNumber(context, '911'),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Barangay hotline: not set up in this prototype.',
              style: TextStyle(
                fontSize: 12,
                color: DinigColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
