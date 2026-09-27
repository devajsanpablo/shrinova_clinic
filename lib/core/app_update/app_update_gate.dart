import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../maintenance/maintenance_controller.dart';
import 'app_update_dialog.dart';
import 'app_update_service.dart';

/// Checks once per app session after the existing maintenance startup has
/// initialized Firebase. The Navigator hosts a non-dismissible required dialog.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({
    super.key,
    required this.maintenance,
    required this.navigatorKey,
    required this.service,
    required this.child,
  });

  final MaintenanceController maintenance;
  final GlobalKey<NavigatorState> navigatorKey;
  final AppUpdateService service;
  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    widget.maintenance.addListener(_maybeCheck);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCheck());
  }

  @override
  void dispose() {
    widget.maintenance.removeListener(_maybeCheck);
    super.dispose();
  }

  void _maybeCheck() {
    if (!mounted ||
        _checked ||
        !widget.maintenance.ready ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _checked = true;
    _check();
  }

  Future<void> _check() async {
    final update = await widget.service.check();
    if (!mounted || update == null || !update.available) return;
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;
    await showDialog<void>(
      context: navigatorContext,
      barrierDismissible: !update.required,
      builder: (_) => AppUpdateDialog(info: update, service: widget.service),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
