import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/core/theme.dart';
import 'package:rmc_clinic_health/screens/doctor/consultation_page.dart';

import '../test/support/patient_database_fake.dart';
import 'load_app_fonts.dart';

void main() {
  testWidgets('consultation visual previews', (tester) async {
    await tester.runAsync(() async {
      await loadAppFonts();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(1440, 1100), const Size(390, 844)]) {
      tester.view.physicalSize = size;
      final state = testAppState();
      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: ConsultationPage(
              key: ValueKey(size.width),
              ticket: state.tickets.first,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppStateScope),
        matchesGoldenFile(
          '../build/ui-previews/consultation-${size.width.toInt()}.png',
        ),
      );
      await tester.ensureVisible(find.text('Clinical assessment'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppStateScope),
        matchesGoldenFile(
          '../build/ui-previews/consultation-entry-${size.width.toInt()}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
