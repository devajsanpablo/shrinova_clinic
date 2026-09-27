import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/core/theme.dart';
import 'package:rmc_clinic_health/models/models.dart';
import 'package:rmc_clinic_health/screens/shared/app_shell.dart';
import 'package:rmc_clinic_health/screens/shared/patients_page.dart';
import 'package:rmc_clinic_health/screens/shared/queue_page.dart';
import 'package:rmc_clinic_health/screens/shared/ticket_form_page.dart';

import 'support/patient_database_fake.dart';

void main() {
  testWidgets('search fields dismiss focus when tapped outside', (
    tester,
  ) async {
    final state = testAppState();
    addTearDown(state.dispose);

    for (final page in [
      const PatientsPage(),
      const QueuePage(role: UserRole.staff),
    ]) {
      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: page),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField).first;
      await tester.tap(field);
      await tester.pump();
      final focusNode = tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode;
      expect(focusNode.hasFocus, isTrue);
      await tester.tapAt(const Offset(4, 4));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    }
  });

  testWidgets('bottom tabs leave the layout while the keyboard is open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final state = testAppState();
    addTearDown(state.dispose);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: AppShell(role: UserRole.staff, profileLoader: () async => null),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('search screens fit $size with large text and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final state = testAppState();

      Future<void> mount(Widget page) async {
        await tester.pumpWidget(
          AppStateScope(
            state: state,
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(body: page),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await mount(const PatientsPage());
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'no-such-patient');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('No patient found'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('No patient found')).dy,
        lessThan(size.height - 240),
      );
      await tester.enterText(
        find.byType(TextField).first,
        state.patients.first.id,
      );
      await tester.pumpAndSettle();
      expect(find.text(state.patients.first.fullName), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(state.patients.first.fullName)).dy,
        lessThan(size.height - 240),
      );
      tester.view.viewInsets = FakeViewPadding.zero;

      await mount(const QueuePage(role: UserRole.staff));
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'no-such-visit');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('No visits found'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('No visits found')).dy,
        lessThan(size.height - 240),
      );
      tester.view.viewInsets = FakeViewPadding.zero;

      await mount(const TicketFormPage());
      await tester.ensureVisible(find.text('Search for a patient'));
      await tester.tap(find.text('Search for a patient'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'no-such-patient');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
}
