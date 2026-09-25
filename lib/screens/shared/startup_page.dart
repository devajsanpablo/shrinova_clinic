import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'login_page.dart';

/// A short launch introduction for the in-memory demo workspace.
class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  late final Timer _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _ready
          ? const LoginPage()
          : Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const ClinicMark(compact: true),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Shrinovva Homeophatic',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Patient care system',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 36),
                        ExcludeSemantics(
                          child: reduceMotion
                              ? const Icon(
                                  Icons.more_horiz_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                )
                              : const SpinKitThreeBounce(
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Opening your workspace…',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
