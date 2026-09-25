import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/model/clinic_profile.dart';
import 'package:rmc_clinic_health/models/models.dart';
import 'package:rmc_clinic_health/screens/shared/profile_greeting.dart';

void main() {
  testWidgets('staff greeting uses the stored first name, not the full name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileGreeting(
            role: UserRole.staff,
            greeting: 'Good evening',
            loadProfile: (role) async => ClinicProfile.fromMap('uid', {
              'firstName': 'Maria Clara',
              'lastName': 'Santos',
              'fullName': 'Maria Clara Santos',
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Good evening, Maria Clara'), findsOneWidget);
    expect(find.textContaining('Santos'), findsNothing);
    expect(find.textContaining('Angela'), findsNothing);
  });

  testWidgets(
    'failed profile lookup keeps a greeting without a placeholder name',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileGreeting(
              role: UserRole.staff,
              greeting: 'Good evening',
              loadProfile: (_) async => throw StateError('offline'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Good evening'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
