import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// One-shot entrances; respect the operating system's reduced-motion preference.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return child
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(
          begin: .025,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
