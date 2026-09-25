import '../test/support/patient_database_fake.dart';
// Generate local visual previews:
// flutter test tool/render_previews_test.dart --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'load_app_fonts.dart';

import 'package:rmc_clinic_health/app.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/core/theme.dart';
import 'package:rmc_clinic_health/models/models.dart';
import 'package:rmc_clinic_health/screens/shared/app_shell.dart';

void main() {
  testWidgets('render clinic previews', (tester) async {
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const ClinicApp());
      await tester.runAsync(() async {
        await loadAppFonts();
      });
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await expectLater(
        find.byType(ClinicApp),
        matchesGoldenFile(
          '../build/ui-previews/login-${size.width.toInt()}.png',
        ),
      );
      await tester.pumpWidget(
        AppStateScope(
          state: testAppState(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const AppShell(role: UserRole.staff),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await expectLater(
        find.byType(AppStateScope),
        matchesGoldenFile(
          '../build/ui-previews/dashboard-${size.width.toInt()}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
