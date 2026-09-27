import 'support/ticket_database_fake.dart';
import 'support/patient_database_fake.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/load_app_fonts.dart';

import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/core/theme.dart';
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
                    builder: (_) => const TicketFormPage(),
                  ),
                ),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async => loadAppFonts());
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    final doctor = find.widgetWithText(
      DropdownButtonFormField<String>,
      'Assigned doctor *',
    );
    await tester.ensureVisible(doctor);
    await tester.tap(doctor);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dr. Test').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Search for a patient'));
  }

  testWidgets('required fields show inline errors without creating a ticket', (
    tester,
  ) async {
    final state = testAppState();
    final count = state.tickets.length;
    await openForm(tester, state);
    await tester.tap(find.text('Review & send'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a patient to continue.'), findsOneWidget);
    expect(find.text('Enter the main complaint.'), findsOneWidget);
    expect(find.text('Enter the reason for consultation.'), findsOneWidget);
    expect(state.tickets.length, count);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search, review and send ticket', (tester) async {
    final state = testAppState();
    final count = state.tickets.length;
    final patient = state.patients.first;
    await openForm(tester, state);
    await tester.tap(find.text('Search for a patient'));
    await tester.pumpAndSettle();
    final patientSearch = find.byType(TextField).last;
    await tester.enterText(patientSearch, 'no-such-patient');
    await tester.pumpAndSettle();
    expect(
      find.text('No patients found. Try a different name or ID.'),
      findsOneWidget,
    );
    await tester.enterText(patientSearch, patient.id);
    await tester.pumpAndSettle();
    await tester.tap(find.text(patient.fullName));
    await tester.pumpAndSettle();

    final complaint = find.widgetWithText(TextFormField, 'Main complaint *');
    await tester.ensureVisible(complaint);
    await tester.enterText(complaint, 'Headache');
    final reason = find.widgetWithText(
      TextFormField,
      'Reason for consultation *',
    );
    await tester.ensureVisible(reason);
    await tester.enterText(reason, 'Started yesterday');
    final search = find.widgetWithText(TextField, 'Search symptoms');
    await tester.ensureVisible(search);
    await tester.enterText(search, 'dizziness');
    await tester.pumpAndSettle();
    // Search results must be visible even for a normally collapsed group.
    final symptom = find.widgetWithText(FilterChip, 'Dizziness');
    await tester.ensureVisible(symptom);
    await tester.tap(symptom);
    await tester.pumpAndSettle();

    const action = 'Review & send';
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
    expect(find.text('Not recorded'), findsNWidgets(4));
    expect(state.tickets.length, count);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Dizziness'), findsOneWidget);
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Send ticket'),
      ),
    );
    await tester.pumpAndSettle();
    expect(state.tickets.length, count + 1);
    final ticket = state.tickets.first;
    expect(
      (state.ticketDatabase as FakeTicketDatabase).records[ticket.id],
      ticket.toMap(),
    );
    expect(ticket.patientId, patient.id);
    expect(ticket.doctorUid, 'doctor-test');
    expect(ticket.doctor, 'Dr. Test');
    expect(ticket.complaint, 'Headache');
    expect(ticket.reason, 'Started yesterday');
    expect(ticket.symptoms, ['Dizziness']);
    expect(ticket.bloodPressure, isEmpty);
    expect(ticket.heartRate, isEmpty);
    expect(ticket.temperature, isEmpty);
    expect(ticket.oxygen, isEmpty);
    expect(ticket.status, TicketStatus.sent);
    expect(find.text('Open form'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed submission preserves form and retries the same ticket', (
    tester,
  ) async {
    final state = testAppState();
    final db = state.ticketDatabase as FakeTicketDatabase;
    db.failWrites = true;
    final count = state.tickets.length;
    await openForm(tester, state);
    await tester.tap(find.text('Search for a patient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(state.patients.first.fullName));
    await tester.pumpAndSettle();
    for (final entry in {
      'Main complaint *': 'Headache',
      'Reason for consultation *': 'Since yesterday',
    }.entries) {
      final field = find.widgetWithText(TextFormField, entry.key);
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    await tester.tap(find.text('Review & send'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Send ticket'));
    await tester.pumpAndSettle();
    expect(state.tickets.length, count);
    expect(find.byType(TicketFormPage), findsOneWidget);
    expect(find.text('Retry save'), findsOneWidget);
    db.failWrites = false;
    await tester.tap(find.text('Retry save'));
    await tester.pumpAndSettle();
    expect(state.tickets.length, count + 1);
    expect(db.records.keys, ['test-ticket-0']);
    expect(db.records.values.single['complaint'], 'Headache');
    expect(find.text('Open form'), findsOneWidget);
  });
}
