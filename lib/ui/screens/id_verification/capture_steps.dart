import 'package:flutter/material.dart';
import '../../theme/dinig_theme.dart';
import 'capture_widgets.dart';
import 'id_mockups.dart';

// -------------------------------------------------------------
// STEP 2: UPLOAD FRONT OF ID
// -------------------------------------------------------------
class FrontOfIdStep extends StatelessWidget {
  final bool hasPhoto;
  final VoidCallback onCapture;
  final VoidCallback onBack;

  const FrontOfIdStep({
    super.key,
    required this.hasPhoto,
    required this.onCapture,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Front of ID',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: DinigColors.darkNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Make sure your ID is clear, well-lit, and all details are visible.',
          style: TextStyle(fontSize: 13, color: DinigColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // ID Card Frame with Corner Brackets
        ViewfinderContainer(
          child: hasPhoto
              ? const CapturedPreview(title: 'Front ID Captured', isFace: false)
              : const FrontIdMockup(),
        ),

        const SizedBox(height: 22),

        // Checklist
        const Checklist([
          'All text and photo are clearly visible',
          'No glare or shadows',
          'ID is not blurry or cropped',
        ]),

        const SizedBox(height: 24),

        // Action Buttons
        CaptureActions(
          takePhotoLabel: 'Take Photo',
          onTakePhoto: onCapture,
          onChooseGallery: onCapture,
        ),

        const SizedBox(height: 16),
        BackStepButton(onPressed: onBack),
      ],
    );
  }
}

// -------------------------------------------------------------
// STEP 3: UPLOAD BACK OF ID
// -------------------------------------------------------------
class BackOfIdStep extends StatelessWidget {
  final bool hasPhoto;
  final VoidCallback onCapture;
  final VoidCallback onBack;

  const BackOfIdStep({
    super.key,
    required this.hasPhoto,
    required this.onCapture,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Back of ID',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: DinigColors.darkNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Make sure the back is clear, well-lit, and all details are visible.',
          style: TextStyle(fontSize: 13, color: DinigColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // ID Card Back Frame with Corner Brackets
        ViewfinderContainer(
          child: hasPhoto
              ? const CapturedPreview(title: 'Back ID Captured', isFace: false)
              : const BackIdMockup(),
        ),

        const SizedBox(height: 22),

        // Checklist
        const Checklist([
          'All text and details are clearly visible',
          'No glare or shadows',
          'ID is not blurry or cropped',
        ]),

        const SizedBox(height: 24),

        // Action Buttons
        CaptureActions(
          takePhotoLabel: 'Take Photo',
          onTakePhoto: onCapture,
          onChooseGallery: onCapture,
        ),

        const SizedBox(height: 16),
        BackStepButton(onPressed: onBack),
      ],
    );
  }
}

// -------------------------------------------------------------
// STEP 4: TAKE A SELFIE
// -------------------------------------------------------------
class SelfieStep extends StatelessWidget {
  final bool hasPhoto;

  /// Current simulated-scan stage label, or null when no scan is running.
  final String? scanLabel;
  final VoidCallback onCapture;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const SelfieStep({
    super.key,
    required this.hasPhoto,
    required this.scanLabel,
    required this.onCapture,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Take a Selfie',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: DinigColors.darkNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'We need a clear photo of you to match with your ID and prevent fraud.',
          style: TextStyle(fontSize: 13, color: DinigColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Face Viewfinder Frame
        ViewfinderContainer(
          child: hasPhoto
              ? const CapturedPreview(title: 'Selfie Matched', isFace: true)
              : const SelfieFaceMockup(),
        ),

        const SizedBox(height: 12),
        Center(
          child: Text(
            scanLabel ??
                (hasPhoto
                    ? 'Face matched (simulated)'
                    : 'Position your face in the frame'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DinigColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Checklist
        const Checklist([
          'Your face is clearly visible',
          'Look straight at the camera',
          'Good lighting (no shadows)',
          'No hats, sunglasses, or filters',
        ]),

        const SizedBox(height: 24),

        // Action Buttons
        CaptureActions(
          takePhotoLabel: hasPhoto ? 'Submit Verification' : 'Take Selfie',
          onTakePhoto: hasPhoto ? onSubmit : onCapture,
          onChooseGallery: onCapture,
        ),

        const SizedBox(height: 16),
        BackStepButton(onPressed: onBack),
      ],
    );
  }
}
