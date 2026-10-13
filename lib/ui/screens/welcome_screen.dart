import 'package:flutter/material.dart';

import '../components/dinig_logo.dart';
import '../theme/dinig_theme.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback? onSignIn;

  const WelcomeScreen({super.key, required this.onGetStarted, this.onSignIn});

  @override
  Widget build(BuildContext context) {
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
                    horizontal: 28,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      const DinigLogo(size: 110),

                      const SizedBox(height: 28),

                      const Text(
                        'DINIG',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: DinigColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Emergency reports for barangay residents',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: DinigColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Dinig ang bawat saklolo. A prototype for emergency reports from barangay residents, with a cancel window before anything is sent.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: DinigColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Features overview
                      _buildFeatureItem(
                        Icons.touch_app,
                        'One-tap SOS with a cancel window',
                        'Shows whether the report was delivered or saved for retry',
                      ),
                      const SizedBox(height: 14),
                      _buildFeatureItem(
                        Icons.rule,
                        'On-device phrase check',
                        'Typed or heard. Rules decide: send, ask, or no alert',
                      ),
                      const SizedBox(height: 14),
                      _buildFeatureItem(
                        Icons.favorite_outline,
                        'Care Mode',
                        'Picture buttons for a child or someone who needs support',
                      ),

                      const Spacer(flex: 2),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: onGetStarted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DinigColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 4,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'GET STARTED',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                      if (onSignIn != null) ...[
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: onSignIn,
                          child: const Text(
                            'Already registered? Sign In with Phone',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: DinigColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DinigColors.softBlue,
            borderRadius: BorderRadius.circular(12),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: DinigColors.darkNavy,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: DinigColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
