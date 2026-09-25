import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import 'maintenance_illustration.dart';
import 'maintenance_controller.dart';

/// Above the Navigator so login, pushed routes and open dialogs are all covered.
/// The navigator remains mounted, preserving unsaved work during maintenance.
class MaintenanceGate extends StatefulWidget {
  const MaintenanceGate({
    super.key,
    required this.controller,
    required this.child,
  });
  final MaintenanceController controller;
  final Widget child;
  @override
  State<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<MaintenanceGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final state = widget.controller;
      final blocked = !state.ready || state.enabled;
      return Stack(
        children: [
          Offstage(
            offstage: blocked,
            child: TickerMode(
              enabled: !blocked,
              child: ExcludeFocus(excluding: blocked, child: widget.child),
            ),
          ),
          if (blocked)
            Positioned.fill(
              child: Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.ready)
                              const MaintenanceIllustration()
                            else
                              const ClinicMark(compact: true),
                            const SizedBox(height: 24),
                            Text(
                              state.ready
                                  ? 'System maintenance'
                                  : 'Shrinovva Homeophatic',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.ready
                                  ? state.message
                                  : state.error ?? 'Patient care system',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (state.ready || state.error != null)
                              FilledButton(
                                onPressed: state.checking
                                    ? null
                                    : state.refresh,
                                child: Text(
                                  state.checking
                                      ? 'Please wait...'
                                      : 'Try again',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
