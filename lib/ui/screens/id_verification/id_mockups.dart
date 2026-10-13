import 'package:flutter/material.dart';
import '../../theme/dinig_theme.dart';

// -------------------------------------------------------------
// MOCKUP CARDS (FRONT, BACK, SELFIE)
// -------------------------------------------------------------
class FrontIdMockup extends StatelessWidget {
  const FrontIdMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, size: 14, color: Color(0xFFDC2626)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'REPUBLIC OF THE PHILIPPINES\nNATIONAL ID',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 50,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.person, color: Color(0xFF475569), size: 38),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MicroLine(width: 90, height: 5),
                    SizedBox(height: 5),
                    _MicroLine(width: 70, height: 4),
                    SizedBox(height: 5),
                    _MicroLine(width: 110, height: 4),
                    SizedBox(height: 5),
                    _MicroLine(width: 60, height: 4),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.qr_code, size: 18, color: Colors.white),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class BackIdMockup extends StatelessWidget {
  const BackIdMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Top Barcode
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                32,
                (i) => Container(
                  width: (i % 3 == 0) ? 2 : 1,
                  color: (i % 2 == 0) ? Colors.white : Colors.transparent,
                ),
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MicroLine(width: 120, height: 4),
                    SizedBox(height: 6),
                    _MicroLine(width: 100, height: 4),
                    SizedBox(height: 6),
                    _MicroLine(width: 80, height: 4),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fingerprint, size: 36, color: DinigColors.primaryBlue),
              ),
            ],
          ),
          const Spacer(),
          const _MicroLine(width: double.infinity, height: 8, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}

class SelfieFaceMockup extends StatelessWidget {
  const SelfieFaceMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: const BoxDecoration(
        color: Color(0xFFDBEAFE),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xFFBFDBFE),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(Icons.face_rounded, size: 84, color: Color(0xFF1E3A8A)),
        ],
      ),
    );
  }
}

class _MicroLine extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;

  const _MicroLine({required this.width, required this.height, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF94A3B8),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
