import 'package:flutter/material.dart';
import '../../theme/dinig_theme.dart';
import 'id_type.dart';

// -------------------------------------------------------------
// STEP 1: VERIFY YOUR IDENTITY
// -------------------------------------------------------------
class IdentityTypeStep extends StatelessWidget {
  final IdType selectedIdType;
  final ValueChanged<IdType> onSelect;
  final VoidCallback onNext;

  const IdentityTypeStep({
    super.key,
    required this.selectedIdType,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Your Identity',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: DinigColors.darkNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'This is a demo of an ID check. No ID is checked and no photo is taken.',
          style: TextStyle(fontSize: 13, color: DinigColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 18),

        // Hero Voice Illustration
        const _VoiceDistressGraphic(),

        const SizedBox(height: 22),
        const Text(
          'Select a valid ID type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: DinigColors.darkNavy,
          ),
        ),
        const SizedBox(height: 12),

        // Radio List of Valid IDs
        ...IdType.values.map(
          (id) => _IdOptionCard(
            id: id,
            isSelected: selectedIdType == id,
            onTap: () => onSelect(id),
          ),
        ),

        const SizedBox(height: 28),

        // Next Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: DinigColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _VoiceDistressGraphic extends StatelessWidget {
  const _VoiceDistressGraphic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: DinigColors.softBlue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DinigColors.lightBlue),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Citizen avatar profile
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: DinigColors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 54, color: DinigColors.darkNavy),
                ),
                const SizedBox(width: 14),

                // Voice waves
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up_rounded, color: DinigColors.primaryBlue, size: 28),
                  ],
                ),
                const SizedBox(width: 12),

                // Speech bubbles
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Help!" Red Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33EF4444),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Help!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // "Tulong!" Blue Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: DinigColors.primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3312203A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Tulong!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IdOptionCard extends StatelessWidget {
  final IdType id;
  final bool isSelected;
  final VoidCallback onTap;

  const _IdOptionCard({
    required this.id,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? DinigColors.softBlue : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? DinigColors.primaryBlue : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? DinigColors.lightBlue : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  id.icon,
                  color: isSelected ? DinigColors.primaryBlue : const Color(0xFF475569),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? DinigColors.darkNavy : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      id.subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? DinigColors.primaryBlue : Colors.white,
                  border: Border.all(
                    color: isSelected ? DinigColors.primaryBlue : const Color(0xFF94A3B8),
                    width: 1.8,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.circle, size: 8, color: Colors.white),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
