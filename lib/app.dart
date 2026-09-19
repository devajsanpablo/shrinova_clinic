import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'screens/startup_page.dart';

class ClinicApp extends StatefulWidget {
  const ClinicApp({super.key});
  @override
  State<ClinicApp> createState() => _ClinicAppState();
}

class _ClinicAppState extends State<ClinicApp> {
  late final AppState state = AppState();
  @override
  Widget build(BuildContext context) => AppStateScope(
    state: state,
    child: MaterialApp(
      title: 'Shrinovva Homeophatic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const StartupPage(),
    ),
  );
}
