import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/theme.dart';
import 'package:rmc_clinic_health/screens/shared/startup_page.dart';

void main() {
  testWidgets('startup respects reduced motion and still opens login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const StartupPage(),
      ),
    );
    expect(find.text('Opening your workspace…'), findsOneWidget);
    expect(find.byType(SpinKitThreeBounce), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Opening your workspace…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup cancels its timer when removed early', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartupPage()));
    expect(find.byType(SpinKitThreeBounce), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
