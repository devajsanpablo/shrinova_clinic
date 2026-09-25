import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/app.dart';
import 'package:rmc_clinic_health/core/theme.dart';

import 'maintenance_test.dart' show FakeMaintenance;

void main() {
  bool placeholderVisible(WidgetTester tester, String text) => tester
      .widgetList<AnimatedOpacity>(
        find.ancestor(
          of: find.text(text),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .any((widget) => widget.opacity == 1);

  testWidgets('hints stay on focus and hide only when typing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Heart rate',
                  hintText: '76',
                  suffixText: 'bpm',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const TextField(decoration: InputDecoration(hintText: 'Search')),
            ],
          ),
        ),
      ),
    );
    Color? hintColor() => tester.widget<Text>(find.text('76')).style?.color;
    final field = find.byType(TextFormField);
    final originalSize = tester.getSize(field);
    expect(hintColor(), AppColors.muted);

    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(hintColor(), AppColors.muted);
    expect(placeholderVisible(tester, '76'), isTrue);
    expect(tester.getSize(field), originalSize);
    expect(
      DefaultTextStyle.of(tester.element(find.text('Heart rate'))).style.color,
      isNot(Colors.transparent),
    );
    expect(tester.widget<Text>(find.text('bpm')).style?.color, AppColors.muted);

    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();
    expect(hintColor(), AppColors.muted);

    await tester.enterText(field, '82');
    await tester.pumpAndSettle();
    expect(placeholderVisible(tester, '76'), isFalse);
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();
    expect(find.text('82'), findsOneWidget);
    expect(placeholderVisible(tester, '76'), isFalse);
    await tester.enterText(field, '');
    await tester.pumpAndSettle();
    expect(placeholderVisible(tester, '76'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login placeholders stay on tap and disappear when typing', (
    tester,
  ) async {
    final maintenance = FakeMaintenance()..ready = true;
    addTearDown(maintenance.dispose);
    await tester.pumpWidget(ClinicApp(maintenance: maintenance));
    await tester.pumpAndSettle();
    final email = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Email or employee ID',
    );
    final password = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Password',
    );
    expect(placeholderVisible(tester, 'Email or employee ID'), isTrue);
    await tester.ensureVisible(email);
    await tester.tap(email);
    await tester.pumpAndSettle();
    expect(placeholderVisible(tester, 'Email or employee ID'), isTrue);
    await tester.enterText(email, 'staff');
    await tester.pumpAndSettle();
    expect(placeholderVisible(tester, 'Email or employee ID'), isFalse);
    await tester.enterText(email, '');
    await tester.pumpAndSettle();
    expect(placeholderVisible(tester, 'Email or employee ID'), isTrue);

    await tester.ensureVisible(password);
    await tester.tap(password);
    await tester.pumpAndSettle();
    expect(placeholderVisible(tester, 'Email or employee ID'), isTrue);
    expect(placeholderVisible(tester, 'Password'), isTrue);
    await tester.enterText(password, 'secret');
    await tester.pumpAndSettle();
    expect(placeholderVisible(tester, 'Password'), isFalse);
    expect(tester.takeException(), isNull);
  });
}
