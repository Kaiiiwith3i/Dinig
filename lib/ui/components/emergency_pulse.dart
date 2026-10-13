import 'package:flutter/material.dart';
import '../theme/dinig_theme.dart';

class EmergencyPulse extends StatefulWidget {
  final double size;
  const EmergencyPulse({super.key, this.size = 120});

  @override
  State<EmergencyPulse> createState() => _EmergencyPulseState();
}

class _EmergencyPulseState extends State<EmergencyPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DinigColors.emergencyRed
                      .withValues(alpha: _opacityAnimation.value),
                ),
              ),
            ),
            Container(
              width: widget.size * 0.7,
              height: widget.size * 0.7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DinigColors.emergencyRed,
                    DinigColors.emergencyDarkRed,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66DC2626),
                    blurRadius: 18,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
