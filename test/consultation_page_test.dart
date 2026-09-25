import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/core/theme.dart';
import 'package:rmc_clinic_health/models/models.dart';
import 'package:rmc_clinic_health/screens/doctor/consultation_page.dart';

import '../tool/load_app_fonts.dart';
import 'support/patient_database_fake.dart';

void main() {
  Future<void> mount(WidgetTester tester, AppState state, Ticket ticket) async {
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: ConsultationPage(ticket: ticket),
        ),
      ),
    );
    await tester.runAsync(loadAppFonts);
    await tester.pumpAndSettle();
  }

  testWidgets('doctor can read full ticket and patient details', (
    tester,
  ) async {
    final state = testAppState();
    final ticket = state.tickets.first;
    final patient = state.patientFor(ticket.patientId);
    await mount(tester, state, ticket);
    for (final value in [
      ticket.id,
      ticket.queueNumber,
      ticket.complaint,
      ticket.reason,
      ticket.notes,
      patient.phone,
      patient.address,
      patient.medicalHistory,
      patient.labs,
    ]) {
      expect(find.text(value), findsWidgets);
    }
    for (final label in [
      'Emergency contact',
      'Emergency phone',
      'Date of birth',
      'Registered',
      'Allergies',
      'Current medications',
      'Consultation history',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('118/76 mmHg'), findsOneWidget);
    expect(find.text('78 bpm'), findsOneWidget);
    expect(find.text('36.7 °C'), findsOneWidget);
    expect(find.text('98 %'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing measurements show explicit empty states on narrow large-text screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final state = testAppState();
      final ticket = Ticket.fromMap(
        'long-firestore-ticket-reference-123456789',
        {
          ...state.tickets.first.toMap(),
          'queueNumber': 'Q-long-firestore-ticket-reference-123456789',
          'bloodPressure': '',
          'heartRate': '',
          'temperature': '',
          'oxygen': '',
          'symptoms': <String>[],
          'notes': '',
        },
      );
      await mount(tester, state, ticket);
      expect(find.text('Not recorded'), findsWidgets);
      expect(find.text('No symptoms recorded'), findsOneWidget);
      expect(find.text(' mmHg'), findsNothing);
      await tester.ensureVisible(find.text('Clinical assessment'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('completed ticket displays saved notes without editing actions', (
    tester,
  ) async {
    final state = testAppState();
    final ticket = Ticket.fromMap('completed', state.tickets.first.toMap())
      ..status = TicketStatus.completed
      ..consultation = Consultation(
        date: DateTime(2026, 9, 23),
        doctor: 'Dr Test',
        complaint: 'Headache',
        diagnosis: 'Saved diagnosis',
        treatment: 'Saved plan',
        prescription: 'Saved prescription',
      );
    await mount(tester, state, ticket);
    expect(find.text('Saved diagnosis'), findsOneWidget);
    expect(find.text('Saved plan'), findsOneWidget);
    expect(find.text('Saved prescription'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Complete consultation'), findsNothing);
  });
}
