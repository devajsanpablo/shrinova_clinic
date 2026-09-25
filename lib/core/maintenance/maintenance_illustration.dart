import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// A bundled illustration so maintenance remains available without a network.
class MaintenanceIllustration extends StatefulWidget {
  const MaintenanceIllustration({super.key});

  @override
  State<MaintenanceIllustration> createState() =>
      _MaintenanceIllustrationState();
}

class _MaintenanceIllustrationState extends State<MaintenanceIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = 0;
    } else {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Maintenance work in progress',
    image: true,
    child: ExcludeSemantics(
      child: SizedBox(
        width: 320,
        height: 230,
        child: AnimatedBuilder(
          animation: _motion,
          child: SvgPicture.asset(
            'assets/illustrations/maintenance.svg',
            fit: BoxFit.contain,
          ),
          builder: (context, illustration) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 210,
                height: 210,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8EFFD),
                  shape: BoxShape.circle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Transform.translate(
                  offset: Offset(0, math.sin(_motion.value * math.pi * 2) * 5),
                  child: illustration,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Transform.rotate(
                      angle: _motion.value * math.pi * 2,
                      child: const Icon(
                        Icons.settings_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
