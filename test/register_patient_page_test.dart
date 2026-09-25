import 'support/ticket_database_fake.dart';
import 'support/patient_database_fake.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/load_app_fonts.dart';

import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/core/theme.dart';
import 'package:rmc_clinic_health/screens/shared/register_patient_page.dart';
import 'package:rmc_clinic_health/models/models.dart';
import 'package:rmc_clinic_health/screens/shared/ticket_form_page.dart';

void main() {
  Future<void> openForm(WidgetTester tester, AppState state) async {
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RegisterPatientPage(),
                  ),
                ),
                child: const Text('Open registration'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async => loadAppFonts());
    await tester.tap(find.text('Open registration'));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String label, String value) async {
    final field = find.widgetWithText(TextFormField, label);
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  testWidgets('required details and invalid phone block registration', (
    tester,
  ) async {
    final state = testAppState();
    final count = state.patients.length;
    await openForm(tester, state);
    await tester.tap(find.text('Review & register'));
    await tester.pumpAndSettle();
    for (final error in [
      'Enter the first name.',
      'Enter the last name.',
      'Choose the date of birth.',
      'Enter a phone number.',
      'Enter the complete address.',
    ]) {
      expect(find.text(error), findsOneWidget);
    }
    await enter(tester, 'First name *', '   ');
    expect(find.text('Enter the first name.'), findsOneWidget);
    await enter(tester, 'Phone number *', 'invalid-phone');
    expect(
      find.text('Use 7–15 digits, with an optional country code.'),
      findsOneWidget,
    );
    expect(state.patients.length, count);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final createTicket in [false, true]) {
    testWidgets(
      'registration preserves details and consent (ticket: $createTicket)',
      (tester) async {
        final state = testAppState();
        final count = state.patients.length;
        final ticketCount = state.tickets.length;
        await openForm(tester, state);
        await enter(tester, 'First name *', '  Ana  ');
        await enter(tester, 'Last name *', '  Cruz  ');
        final birth = find.widgetWithText(TextFormField, 'Date of birth *');
        await tester.ensureVisible(birth);
        await tester.tap(birth);
        await tester.pumpAndSettle();
        final localizations = MaterialLocalizations.of(
          tester.element(find.byType(DatePickerDialog)),
        );
        await tester.tap(
          find.byTooltip(localizations.inputDateModeButtonLabel),
        );
        await tester.pumpAndSettle();
        final input = find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(input, '12/31/2999');
        await tester.tap(find.text(localizations.okButtonLabel));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        await tester.enterText(input, '05/12/2000');
        await tester.tap(find.text(localizations.okButtonLabel));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsNothing);
        await enter(tester, 'Phone number *', '+63 917 123 4567');
        await enter(
          tester,
          'Complete address *',
          '  123 Main Street, Manila  ',
        );
        await enter(tester, 'Medical history', '  Previous surgery  ');
        await enter(tester, 'Allergies', ' Penicillin, , Peanuts, ');
        await enter(tester, 'Existing conditions', ' Asthma, , Migraine ');
        await enter(
          tester,
          'Current medications',
          ' Medication A, Medication B ',
        );
        await enter(tester, 'Contact name', '  Juan Cruz  ');
        await enter(tester, 'Contact phone', '0918 123 4567');
        if (createTicket) {
          final toggle = find.byType(SwitchListTile);
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          final search = find.widgetWithText(TextField, 'Search symptoms');
          await tester.ensureVisible(search);
          await tester.enterText(search, 'no-such-symptom');
          await tester.pumpAndSettle();
          expect(
            find.text('No matching symptoms. Try another term.'),
            findsOneWidget,
          );
          await tester.enterText(search, 'dizziness');
          await tester.pumpAndSettle();
          final symptom = find.widgetWithText(FilterChip, 'Dizziness');
          await tester.ensureVisible(symptom);
          await tester.tap(symptom);
          await tester.pumpAndSettle();
          expect(find.widgetWithText(InputChip, 'Dizziness'), findsOneWidget);
          // Selections survive disabling and re-enabling the optional ticket.
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(
            find.widgetWithText(TextField, 'Search symptoms'),
            findsNothing,
          );
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(find.widgetWithText(InputChip, 'Dizziness'), findsOneWidget);
        }
        final reviewLabel = createTicket
            ? 'Review & continue'
            : 'Review & register';
        final confirmLabel = createTicket
            ? 'Register & continue'
            : 'Register patient';
        await tester.tap(find.text(reviewLabel));
        await tester.pumpAndSettle();
        expect(find.text('Review patient details'), findsOneWidget);
        expect(find.text('Asthma, Migraine'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, confirmLabel),
              )
              .onPressed,
          isNull,
        );
        expect(state.patients.length, count);
        await tester.tap(find.text('Keep editing'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(
                find.widgetWithText(TextFormField, 'Contact name'),
              )
              .controller!
              .text,
          '  Juan Cruz  ',
        );
        await tester.tap(find.text(reviewLabel));
        await tester.pumpAndSettle();
        final consent = find.byType(CheckboxListTile);
        await tester.ensureVisible(consent);
        await tester.tap(consent);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, confirmLabel));
        await tester.pumpAndSettle();
        expect(state.patients.length, count + 1);
        final patient = state.patients.first;
        expect(patient.fullName, 'Ana Cruz');
        expect(patient.dateOfBirth, DateTime(2000, 5, 12));
        expect(patient.phone, '+63 917 123 4567');
        expect(patient.address, '123 Main Street, Manila');
        expect(patient.medicalHistory, 'Previous surgery');
        expect(patient.allergies, ['Penicillin', 'Peanuts']);
        expect(patient.conditions, ['Asthma', 'Migraine']);
        expect(patient.medications, ['Medication A', 'Medication B']);
        expect(patient.emergencyContactName, 'Juan Cruz');
        expect(patient.emergencyContactPhone, '0918 123 4567');
        expect(state.tickets.length, ticketCount);
        if (createTicket) {
          expect(find.byType(TicketFormPage), findsOneWidget);
          expect(find.byType(RegisterPatientPage), findsNothing);
          expect(find.text('Ana Cruz'), findsOneWidget);
          expect(find.widgetWithText(InputChip, 'Dizziness'), findsOneWidget);
          await tester.tap(find.text('Review & send'));
          await tester.pumpAndSettle();
          expect(find.text('Enter the main complaint.'), findsOneWidget);
          expect(state.tickets.length, ticketCount);
          await enter(tester, 'Main complaint *', 'Dizziness');
          await enter(
            tester,
            'Reason for consultation *',
            'Started this morning',
          );
          await tester.tap(find.text('Review & send'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Send ticket'));
          await tester.pumpAndSettle();
          expect(state.tickets.length, ticketCount + 1);
          expect(
            (state.ticketDatabase as FakeTicketDatabase).records[state
                .tickets
                .first
                .id],
            state.tickets.first.toMap(),
          );
          expect(state.tickets.first.patientId, patient.id);
          expect(state.tickets.first.symptoms, ['Dizziness']);
          expect(state.tickets.first.status, TicketStatus.sent);
          expect(state.patients.length, count + 1);
        }
        expect(find.text('Open registration'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('registration fits a narrow screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openForm(tester, testAppState());
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -5000),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final toggle = find.byType(SwitchListTile);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(TextField, 'Search symptoms'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
