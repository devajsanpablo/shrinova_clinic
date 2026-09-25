import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'core/maintenance/maintenance_controller.dart';
import 'core/maintenance/maintenance_gate.dart';
import 'screens/shared/startup_page.dart';

class ClinicApp extends StatefulWidget {
  const ClinicApp({super.key, this.maintenance});
  final MaintenanceController? maintenance;
  @override
  State<ClinicApp> createState() => _ClinicAppState();
}

class _ClinicAppState extends State<ClinicApp> {
  late final AppState state = AppState();
  late final MaintenanceController maintenance =
      widget.maintenance ?? MaintenanceController();
  @override
  void dispose() {
    if (widget.maintenance == null) maintenance.dispose();
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppStateScope(
    state: state,
    child: MaterialApp(
      title: 'Shrinovva Homeophatic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) =>
          MaintenanceGate(controller: maintenance, child: child!),
      home: const StartupPage(),
    ),
  );
}
