import 'package:flutter/material.dart';
import '../theme/dinig_theme.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingScreen({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              const Text(
                'What this prototype does',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: DinigColors.darkNavy,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'DINIG is an early prototype. Here is what is real and what is not.',
                style: TextStyle(
                  fontSize: 14,
                  color: DinigColors.textSecondary,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              _buildSection(
                icon: Icons.check_circle_outline,
                title: 'Works today',
                lines: const [
                  'SOS button with a cancel window before anything is sent',
                  'Reports are sent, or saved on the phone and retried',
                  'On-device phrase check (typed text, rule-based)',
                  'Care Mode with picture buttons',
                ],
              ),

              const SizedBox(height: 14),

              _buildSection(
                icon: Icons.science_outlined,
                title: 'Simulated',
                lines: const [
                  'Location is a fixed demo coordinate until you allow location',
                  'Report audio is a placeholder tone until you allow the microphone',
                  'The ID check is a demo',
                ],
              ),

              const SizedBox(height: 14),

              _buildSection(
                icon: Icons.construction,
                title: 'New and still being tested',
                lines: const [
                  'Voice trigger: when you switch it on, the phone listens for Help, Tulong or Saklolo and starts the same cancel countdown.',
                  'Phone location and audio recording on reports.',
                  'None of these is proven on a real phone yet.',
                ],
              ),

              const SizedBox(height: 28),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DinigColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> lines,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF4FA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: DinigColors.softBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: DinigColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: DinigColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DinigColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
