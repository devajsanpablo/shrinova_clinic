import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/core/theme.dart';
import 'package:rmc_clinic_health/models/models.dart';
import 'package:rmc_clinic_health/screens/shared/app_shell.dart';
import 'package:rmc_clinic_health/screens/shared/notifications_settings_pages.dart';

import 'support/patient_database_fake.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Settings content clears bottom navigation at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      tester.view.padding = const FakeViewPadding(bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetPadding);
      final state = testAppState();
      addTearDown(state.dispose);

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: MaterialApp(
            theme: AppTheme.light,
            home: AppShell(
              role: UserRole.staff,
              profileLoader: () async => null,
              initialIndex: 3,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final settings = find.byType(SettingsPage);
      final scrollable = find
          .descendant(of: settings, matching: find.byType(Scrollable))
          .first;
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump(const Duration(milliseconds: 100));

      final signOut = find.widgetWithText(OutlinedButton, 'Sign out');
      final contentBottom = tester.getBottomLeft(signOut).dy;
      final navTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
      expect(contentBottom, lessThan(navTop));
      expect(find.text('Appearance & session'), findsNothing);
      expect(find.text('Email summaries'), findsNothing);
      expect(
        tester.getBottomLeft(find.byType(NavigationBar)).dy,
        lessThanOrEqualTo(size.height - 24),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Settings remains scrollable on a tablet without bottom tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = testAppState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: AppShell(
            role: UserRole.staff,
            profileLoader: () async => null,
            initialIndex: 3,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SettingsPage),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
