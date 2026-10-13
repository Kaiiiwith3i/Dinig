import 'package:flutter/material.dart';
import '../../theme/dinig_theme.dart';

// -------------------------------------------------------------
// CORNER BRACKETS VIEWFINDER CONTAINER
// -------------------------------------------------------------
class ViewfinderContainer extends StatelessWidget {
  final Widget child;

  const ViewfinderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centered Inner Card / Portrait
            Padding(
              padding: const EdgeInsets.all(24),
              child: child,
            ),

            // Corner Brackets Overlay
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomPaint(
                  painter: _CornerBracketsPainter(
                    color: DinigColors.primaryBlue,
                    length: 26,
                    strokeWidth: 3.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CapturedPreview extends StatelessWidget {
  final String title;
  final bool isFace;

  const CapturedPreview({super.key, required this.title, required this.isFace});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF22C55E), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFace ? Icons.face_retouching_natural : Icons.check_circle_outline,
            size: 48,
            color: const Color(0xFF15803D),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF15803D),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Ready to verify',
            style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// CHECKLIST COMPONENT
// -------------------------------------------------------------
class Checklist extends StatelessWidget {
  final List<String> items;

  const Checklist(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: DinigColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13,
                        color: DinigColors.darkNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// -------------------------------------------------------------
// CAPTURE ACTIONS (TAKE PHOTO OR GALLERY)
// -------------------------------------------------------------
class CaptureActions extends StatelessWidget {
  final String takePhotoLabel;
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseGallery;

  const CaptureActions({
    super.key,
    required this.takePhotoLabel,
    required this.onTakePhoto,
    required this.onChooseGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onTakePhoto,
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            label: Text(
              takePhotoLabel,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DinigColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onChooseGallery,
            icon: const Icon(Icons.image_outlined, size: 20, color: DinigColors.primaryBlue),
            label: const Text(
              'Choose from Gallery',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: DinigColors.primaryBlue,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: DinigColors.primaryBlue, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
          ),
        ),
      ],
    );
  }
}

class BackStepButton extends StatelessWidget {
  final VoidCallback onPressed;

  const BackStepButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF64748B)),
        label: const Text(
          'Back',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// CORNER BRACKETS CUSTOM PAINTER
// -------------------------------------------------------------
class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double length;
  final double strokeWidth;

  _CornerBracketsPainter({
    required this.color,
    required this.length,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Top-Left (┌)
    canvas.drawLine(const Offset(0, 0), Offset(length, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, length), paint);

    // Top-Right (┐)
    canvas.drawLine(Offset(w, 0), Offset(w - length, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, length), paint);

    // Bottom-Left (└)
    canvas.drawLine(Offset(0, h), Offset(length, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - length), paint);

    // Bottom-Right (┘)
    canvas.drawLine(Offset(w, h), Offset(w - length, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
