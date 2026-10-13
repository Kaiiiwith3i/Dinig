import 'package:flutter/material.dart';

/// The DINIG mark, rendered from the brand file `assets/brand/dinig_icon.svg`.
/// Decorative: it always sits beside the name, so screen readers skip it.
class DinigLogo extends StatelessWidget {
  final double size;

  const DinigLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/dinig_icon.png',
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
