import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/app_update/app_update_gate.dart';
import 'package:rmc_clinic_health/core/app_update/app_update_service.dart';
import 'package:rmc_clinic_health/core/maintenance/maintenance_controller.dart';
import 'package:rmc_clinic_health/model/app_update_info.dart';

class _ReadyMaintenance extends MaintenanceController {
  _ReadyMaintenance() {
    ready = true;
  }

  @override
  Future<void> refresh() async {}
}

class _FakeUpdates extends AppUpdateService {
  int checks = 0;

  @override
  Future<AppUpdateInfo?> check() async {
    checks++;
    return AppUpdateInfo.fromValues(
      installedVersion: '1.0.0',
      installedBuild: 1,
      values: {
        'latest_version': '1.1.0',
        'latest_build': '2',
        'minimum_build': '2',
        'force_update': 'true',
        'apk_url': 'https://firebasestorage.googleapis.com/example.apk',
      },
    );
  }
}

void main() {
  testWidgets('startup checks once and shows the required update', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final maintenance = _ReadyMaintenance();
    addTearDown(maintenance.dispose);
    final updates = _FakeUpdates();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => AppUpdateGate(
          maintenance: maintenance,
          navigatorKey: navigatorKey,
          service: updates,
          child: child!,
        ),
        home: const Scaffold(body: Text('Clinic login')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update Required'), findsOneWidget);
    expect(updates.checks, 1);
    await tester.pump();
    expect(updates.checks, 1);
    debugDefaultTargetPlatformOverride = null;
  });
}
