import 'package:flutter/material.dart';
import '../view_models/dinig_view_model.dart';
import 'id_verification/capture_steps.dart';
import 'id_verification/completion_dialog.dart';
import 'id_verification/id_type.dart';
import 'id_verification/identity_type_step.dart';
import 'id_verification/verification_header.dart';

export 'id_verification/id_type.dart';

class IdVerificationScreen extends StatefulWidget {
  final DinigViewModel viewModel;
  final VoidCallback onVerificationComplete;

  const IdVerificationScreen({
    super.key,
    required this.viewModel,
    required this.onVerificationComplete,
  });

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  int _currentStep = 1; // 1: ID Type, 2: Front, 3: Back, 4: Selfie
  IdType _selectedIdType = IdType.nationalId;

  bool _hasFrontPhoto = false;
  bool _hasBackPhoto = false;
  bool _hasSelfiePhoto = false;

  // Guards against double-taps skipping steps or opening two dialogs.
  bool _busy = false;
  bool _finished = false;

  // Simulated face scan: 0 idle, then 1..3 stages (no camera is used).
  int _scanStage = 0;
  static const _scanLabels = ['', 'Detecting face…', 'Hold still…', 'Blink once…'];

  void _onNextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    } else {
      _finishVerification();
    }
  }

  void _onPrevStep() {
    if (_busy || _currentStep <= 1) return;
    setState(() {
      _currentStep--;
    });
  }

  Future<void> _capturePhotoForCurrentStep() async {
    if (_busy) return;
    _busy = true;

    if (_currentStep == 4) {
      for (var stage = 1; stage <= 3; stage++) {
        if (!mounted) return;
        setState(() => _scanStage = stage);
        await Future.delayed(const Duration(milliseconds: 700));
      }
      if (!mounted) return;
    }

    setState(() {
      _scanStage = 0;
      if (_currentStep == 2) _hasFrontPhoto = true;
      if (_currentStep == 3) _hasBackPhoto = true;
      if (_currentStep == 4) _hasSelfiePhoto = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          switch (_currentStep) {
            2 => 'Front of ${_selectedIdType.title} captured!',
            3 => 'Back of ${_selectedIdType.title} captured!',
            _ => 'Selfie photo captured!',
          },
        ),
        backgroundColor: const Color(0xFF166534),
        duration: const Duration(milliseconds: 1200),
      ),
    );

    // Auto-advance after brief delay to delight user
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _busy = false;
    _onNextStep();
  }

  void _finishVerification() {
    if (_finished) return;
    _finished = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DemoCompleteDialog(
        idTypeTitle: _selectedIdType.title,
        onGoToDashboard: () {
          Navigator.of(ctx).pop();
          widget.onVerificationComplete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [            // Top App Bar
            IdTopAppBar(currentStep: _currentStep, onBack: _onPrevStep),

            // Step Progress Indicator
            IdStepIndicator(currentStep: _currentStep),

            const SizedBox(height: 8),
            const Text(
              'DEMO • Simulated verification — no camera or ID data is used',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),

            const SizedBox(height: 12),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: switch (_currentStep) {
                  1 => IdentityTypeStep(
                      selectedIdType: _selectedIdType,
                      onSelect: (id) => setState(() => _selectedIdType = id),
                      onNext: _onNextStep,
                    ),
                  2 => FrontOfIdStep(
                      hasPhoto: _hasFrontPhoto,
                      onCapture: _capturePhotoForCurrentStep,
                      onBack: _onPrevStep,
                    ),
                  3 => BackOfIdStep(
                      hasPhoto: _hasBackPhoto,
                      onCapture: _capturePhotoForCurrentStep,
                      onBack: _onPrevStep,
                    ),
                  _ => SelfieStep(
                      hasPhoto: _hasSelfiePhoto,
                      scanLabel: _scanStage > 0 ? _scanLabels[_scanStage] : null,
                      onCapture: _capturePhotoForCurrentStep,
                      onSubmit: _finishVerification,
                      onBack: _onPrevStep,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
