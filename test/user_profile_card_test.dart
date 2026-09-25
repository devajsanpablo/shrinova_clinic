import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/model/clinic_profile.dart';
import 'package:rmc_clinic_health/models/models.dart';
import 'package:rmc_clinic_health/screens/shared/user_profile_card.dart';

void main() {
  for (final role in UserRole.values) {
    testWidgets('$role displays fetched details on a narrow screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<ClinicProfile?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileCard(
              role: role,
              loadProfile: (requested) {
                expect(requested, role);
                return pending.future;
              },
            ),
          ),
        ),
      );
      expect(find.text('Loading your profile...'), findsOneWidget);
      pending.complete(
        ClinicProfile.fromMap('uid', {
          'firstName': 'Maria',
          'lastName': 'Santos',
          'email': 'maria.santos@clinic.example.com',
          'contact': '09123456789',
          'userId': 'STAFF-042',
          'specialization': 'Family Medicine',
          'licenseNumber': 'PRC-1234567',
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(
        find.text('Email: maria.santos@clinic.example.com'),
        findsOneWidget,
      );
      expect(find.text('Phone: 09123456789'), findsOneWidget);
      expect(
        find.text(
          role == UserRole.doctor
              ? 'Specialty: Family Medicine'
              : 'Staff ID: STAFF-042',
        ),
        findsOneWidget,
      );
      expect(find.text('Angela Ramos'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'failed profile load can be retried and handles missing profile',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserProfileCard(
              role: UserRole.staff,
              loadProfile: (_) async {
                if (++calls == 1) throw StateError('offline');
                return null;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to load your profile. Please try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(
        find.text(
          'Your profile could not be found. Contact your clinic administrator.',
        ),
        findsOneWidget,
      );
    },
  );
}
