import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/screens/shared/feature_walkthrough_page.dart';
import 'package:rmc_clinic_health/screens/shared/register_patient_page.dart';

import 'support/patient_database_fake.dart';

// Timers between targets intentionally wait for route/entrance animations.
Future<void> settleTour(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(1200, 900),
    const Size(844, 390),
  ]) {
    testWidgets('requires real control taps and opens registration at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = testAppState();
      final initialPatients = state.patients.length;
      final initialTickets = state.tickets.length;
      final overview = GlobalKey();
      final register = GlobalKey();
      final back = GlobalKey();
      late FeatureWalkthrough tour;
      late BuildContext host;
      var overviewOpened = false;
      var ended = false;
      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                host = context;
                return Scaffold(
                  body: Column(
                    children: [
                      TextButton(
                        key: overview,
                        onPressed: () {},
                        child: const Text('Overview'),
                      ),
                      TextButton(
                        key: register,
                        onPressed: () {},
                        child: const Text('Register patient'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      tour = FeatureWalkthrough(
        context: host,
        onEnd: () => ended = true,
        steps: [
          WalkthroughStep(
            target: overview,
            title: 'Tap Overview',
            description: 'View today’s visits.',
            onTap: () => overviewOpened = true,
          ),
          WalkthroughStep(
            target: register,
            title: 'Tap Register patient',
            description: 'Open the actual form.',
            onTap: () async {
              await Navigator.of(host).push(
                MaterialPageRoute<void>(
                  builder: (_) => RegisterPatientPage(walkthroughBackKey: back),
                ),
              );
            },
          ),
          WalkthroughStep(
            target: overview,
            title: 'Tour resumed',
            description: 'Tap Overview to finish.',
            onTap: () {},
          ),
        ],
      );
      tour.show();
      await settleTour(tester);
      expect(find.text('Tap Overview'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      expect(find.text('DEMO PREVIEW'), findsNothing);
      await tester.tapAt(Offset(size.width - 10, size.height - 10));
      await settleTour(tester);
      expect(overviewOpened, isFalse);
      await tester.tapAt(tester.getCenter(find.byKey(overview)));
      await settleTour(tester);
      expect(overviewOpened, isTrue);
      expect(find.text('Tap Register patient'), findsOneWidget);
      await tester.tapAt(tester.getCenter(find.byKey(register)));
      await settleTour(tester);
      expect(find.byType(RegisterPatientPage), findsOneWidget);
      expect(find.text('Tour resumed'), findsNothing);
      final firstName = find.widgetWithText(TextFormField, 'First name *');
      await tester.ensureVisible(firstName);
      await tester.enterText(firstName, 'Alex');
      await tester.pumpAndSettle();
      expect(find.text('Alex'), findsWidgets);
      await tester.tapAt(tester.getCenter(find.byKey(back)));
      await settleTour(tester);
      expect(find.text('Tour resumed'), findsOneWidget);
      await tester.tapAt(tester.getCenter(find.byKey(overview)));
      await settleTour(tester);
      expect(ended, isTrue);
      expect(find.byType(RegisterPatientPage), findsNothing);
      expect(state.patients.length, initialPatients);
      expect(state.tickets.length, initialTickets);
      expect(tester.takeException(), isNull);
      tour.dispose();
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  testWidgets('skip dismisses without invoking the highlighted action', (
    tester,
  ) async {
    final key = GlobalKey();
    late BuildContext host;
    var tapped = false;
    var ended = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            host = context;
            return Scaffold(
              body: TextButton(
                key: key,
                onPressed: () {},
                child: const Text('Overview'),
              ),
            );
          },
        ),
      ),
    );
    final tour = FeatureWalkthrough(
      context: host,
      onEnd: () => ended = true,
      steps: [
        WalkthroughStep(
          target: key,
          title: 'Tap Overview',
          description: 'Start here.',
          onTap: () => tapped = true,
        ),
      ],
    );
    tour.show();
    await settleTour(tester);
    await tester.tap(find.text('Skip tour'));
    await settleTour(tester);
    expect(ended, isTrue);
    expect(tapped, isFalse);
    expect(find.text('Tap Overview'), findsNothing);
    expect(tester.takeException(), isNull);
    tour.dispose();
  });
}
