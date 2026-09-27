import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/app_update/app_update_dialog.dart';
import 'package:rmc_clinic_health/core/app_update/app_update_service.dart';
import 'package:rmc_clinic_health/model/app_update_info.dart';

void main() {
  Future<void> openDialog(WidgetTester tester, AppUpdateKind kind) async {
    final info = AppUpdateInfo(
      installedVersion: '1.0.0',
      installedBuild: 1,
      latestVersion: '1.1.0',
      latestBuild: 2,
      minimumBuild: 1,
      kind: kind,
      releaseNotes: 'Improved patient search\nFixed ticket issues',
      apkUrl: Uri.parse('https://firebasestorage.googleapis.com/example.apk'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: kind != AppUpdateKind.required,
                builder: (_) =>
                    AppUpdateDialog(info: info, service: AppUpdateService()),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('optional update offers Later', (tester) async {
    await openDialog(tester, AppUpdateKind.optional);
    expect(find.text('Update Available'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('• Improved patient search'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
  });

  testWidgets('required update cannot be dismissed with back or barrier', (
    tester,
  ) async {
    await openDialog(tester, AppUpdateKind.required);
    expect(find.text('Update Required'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsOneWidget);
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsOneWidget);
  });
}
