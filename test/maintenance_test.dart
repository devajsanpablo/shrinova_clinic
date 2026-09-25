import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/app.dart';
import 'package:rmc_clinic_health/core/maintenance/maintenance_controller.dart';
import 'package:rmc_clinic_health/core/maintenance/maintenance_gate.dart';
import 'package:rmc_clinic_health/core/maintenance/maintenance_illustration.dart';

class FakeMaintenance extends MaintenanceController {
  @override
  Future<void> refresh() async {}
  void update(bool value) {
    ready = true;
    enabled = value;
    notifyListeners();
  }
}

void main() {
  testWidgets('startup shows branding and keeps login blocked until ready', (
    tester,
  ) async {
    final state = FakeMaintenance();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MaintenanceGate(
          controller: state,
          child: const Scaffold(body: Text('Login content')),
        ),
      ),
    );
    expect(find.text('Shrinovva Homeophatic'), findsOneWidget);
    expect(find.text('Checking system availability'), findsNothing);
    expect(find.byType(MaintenanceIllustration), findsNothing);
    expect(find.text('Login content'), findsNothing);
    state.error = 'Check your connection and retry.';
    state.notifyListeners();
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Login content'), findsNothing);
    state.update(false);
    await tester.pump();
    expect(find.text('Login content'), findsOneWidget);
  });

  testWidgets('maintenance illustration respects reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: MaintenanceIllustration()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MaintenanceIllustration), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets(
      'Maintenance covers existing routes and restores work at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final state = FakeMaintenance()..ready = true;
        addTearDown(state.dispose);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                MaintenanceGate(controller: state, child: child!),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: TextField()),
                    ),
                  ),
                  child: const Text('Open work'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open work'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          'Unsaved clinical notes',
        );
        state.update(true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('System maintenance'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(tester.takeException(), isNull);
        state.update(false);
        await tester.pumpAndSettle();
        expect(find.text('System maintenance'), findsNothing);
        expect(find.text('Unsaved clinical notes'), findsOneWidget);
      },
    );
  }

  testWidgets('Both role logins are blocked while maintenance is active', (
    tester,
  ) async {
    final state = FakeMaintenance()
      ..ready = true
      ..enabled = true;
    await tester.pumpWidget(ClinicApp(maintenance: state));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('System maintenance'), findsOneWidget);
    expect(find.text('Clinic Staff'), findsNothing);
    expect(find.text('Doctor'), findsNothing);
    state.update(false);
    await tester.pumpAndSettle();
    expect(find.text('Clinic Staff'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
