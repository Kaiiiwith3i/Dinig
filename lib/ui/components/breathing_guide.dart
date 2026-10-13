import 'package:flutter/material.dart';

/// Slow in/out circle shown during the cancel countdown in Care Mode.
/// Local only, no sound; stays still when the OS asks to reduce motion.
class BreathingGuide extends StatefulWidget {
  const BreathingGuide({super.key});

  @override
  State<BreathingGuide> createState() => _BreathingGuideState();
}

class _BreathingGuideState extends State<BreathingGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) _controller.stop();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final breathingIn =
            _controller.status == AnimationStatus.forward || reduceMotion;
        final scale = reduceMotion ? 0.8 : 0.6 + 0.4 * _controller.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 150,
              child: Center(
                child: Container(
                  width: 140 * scale,
                  height: 140 * scale,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x66FFFFFF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reduceMotion
                  ? 'Breathe slowly. You can still cancel.'
                  : (breathingIn ? 'Breathe in…' : 'Breathe out…'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}
