import 'package:flutter/material.dart';
import '../../components/dinig_logo.dart';
import '../../theme/dinig_theme.dart';

// -------------------------------------------------------------
// TOP APP BAR WITH BRANDING
// -------------------------------------------------------------
class IdTopAppBar extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBack;

  const IdTopAppBar({super.key, required this.currentStep, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          currentStep > 1
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 20, color: DinigColors.darkNavy),
                  onPressed: onBack,
                )
              : const SizedBox(width: 48, height: 48),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DinigLogo(size: 26),
                    const SizedBox(width: 8),
                    const Text(
                      'DINIG',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: DinigColors.darkNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'A safer community, together.',
                  style: TextStyle(fontSize: 11, color: DinigColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// STEP PROGRESS BAR (1 ID Type -> 2 Front -> 3 Back -> 4 Selfie)
// -------------------------------------------------------------
class IdStepIndicator extends StatelessWidget {
  final int currentStep;

  const IdStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['ID Type', 'Front', 'Back', 'Selfie'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final stepNum = index + 1;
          final isCompleted = stepNum < currentStep;
          final isActive = stepNum == currentStep;

          return Expanded(
            child: Row(
              children: [
                // Step Node
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isCompleted || isActive)
                            ? DinigColors.primaryBlue
                            : Colors.white,
                        border: Border.all(
                          color: (isCompleted || isActive)
                              ? DinigColors.primaryBlue
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text(
                                '$stepNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive
                            ? DinigColors.primaryBlue
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                // Connecting Line between steps
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                      color: stepNum < currentStep
                          ? DinigColors.primaryBlue
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
