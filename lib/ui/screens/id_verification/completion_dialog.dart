import 'package:flutter/material.dart';
import '../../theme/dinig_theme.dart';

class DemoCompleteDialog extends StatelessWidget {
  final String idTypeTitle;
  final VoidCallback onGoToDashboard;

  const DemoCompleteDialog({
    super.key,
    required this.idTypeTitle,
    required this.onGoToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: DinigColors.primaryBlue, size: 28),
          SizedBox(width: 10),
          Text('Demo check complete'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Demo verification complete. No real ID check was performed and no images were captured or stored.',
            style: TextStyle(fontSize: 14, color: DinigColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF166534), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simulated check: $idTypeTitle',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: onGoToDashboard,
          style: ElevatedButton.styleFrom(
            backgroundColor: DinigColors.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('GO TO DASHBOARD'),
        ),
      ],
    );
  }
}
