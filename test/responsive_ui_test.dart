import 'support/patient_database_fake.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/load_app_fonts.dart';

import 'package:rmc_clinic_health/app.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/core/theme.dart';
import 'package:rmc_clinic_health/models/models.dart';
import 'package:rmc_clinic_health/screens/shared/app_shell.dart';
import 'package:rmc_clinic_health/screens/shared/patient_profile_page.dart';
import 'package:rmc_clinic_health/screens/doctor/consultation_page.dart';
import 'package:rmc_clinic_health/screens/shared/ticket_form_page.dart';
import 'package:rmc_clinic_health/screens/shared/register_patient_page.dart';
import 'package:rmc_clinic_health/screens/shared/patients_page.dart';

import 'maintenance_test.dart' show FakeMaintenance;

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1440, 1000),
  ]) {
    testWidgets(
      'login, role navigation, and medical screens fit ${size.width}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final maintenance = FakeMaintenance()..ready = true;
        addTearDown(maintenance.dispose);
        await tester.pumpWidget(ClinicApp(maintenance: maintenance));
        // Finish loading bundled fonts before measuring animated route layouts.
        await tester.runAsync(() async {
          await loadAppFonts();
        });
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        final signIn = find.text('Sign in as Staff');
        await tester.ensureVisible(signIn);
        await tester.tap(signIn);
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        expect(
          find.text('Enter your email and password to continue.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        final state = testAppState();
        Future<void> mount(Widget page) async {
          await tester.pumpWidget(
            AppStateScope(
              state: state,
              child: MaterialApp(theme: AppTheme.light, home: page),
            ),
          );
          await tester.pumpAndSettle(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
        }

        await mount(const AppShell(role: UserRole.doctor));
        final queueIcon = find.byIcon(Icons.view_list_outlined);
        await tester.tap(queueIcon);
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        expect(find.text('Your patient queue'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.people_alt_outlined));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        expect(find.byType(PatientsPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        await mount(const Scaffold(body: PatientsPage()));
        await tester.enterText(
          find.byType(TextField).first,
          'no-matching-patient',
        );
        await tester.pumpAndSettle();
        expect(find.text('No patient found'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await mount(PatientProfilePage(patient: state.patients.first));
        await mount(ConsultationPage(ticket: state.tickets.first));
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -2400),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await mount(const TicketFormPage());
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await mount(const RegisterPatientPage());
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -5000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
