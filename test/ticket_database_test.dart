import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/data/mock_data.dart';
import 'package:rmc_clinic_health/model/ticket.dart';
import 'package:rmc_clinic_health/model/patient.dart';

import 'support/patient_database_fake.dart';
import 'support/ticket_database_fake.dart';

void main() {
  test(
    'every ticket field survives serialization for all statuses and priorities',
    () {
      for (final status in TicketStatus.values) {
        for (final priority in Priority.values) {
          final data = {
            ...mockTickets.first.toMap(),
            'status': status.name,
            'priority': priority.name,
          };
          expect(Ticket.fromMap('id', data).toMap(), data);
        }
      }
    },
  );
  test(
    'tickets and patient references survive a fresh clinic session',
    () async {
      final patients = FakePatientDatabase();
      final tickets = FakeTicketDatabase();
      final state = AppState(database: patients, ticketDatabase: tickets);
      for (final patient in mockPatients) {
        await state.addPatient(patient);
      }
      await state.addTicket(mockTickets.first);
      final restored = AppState(database: patients, ticketDatabase: tickets);
      await restored.loadClinicData();
      expect(restored.tickets.single.toMap(), mockTickets.first.toMap());
      expect(
        restored.patientFor(restored.tickets.single.patientId).id,
        mockTickets.first.patientId,
      );
      restored.clearSession();
      expect(restored.tickets, isEmpty);
    },
  );
  test(
    'failed writes leave queue unchanged and retries do not duplicate',
    () async {
      final db = FakeTicketDatabase()..failWrites = true;
      final state = AppState(ticketDatabase: db);
      await expectLater(state.addTicket(mockTickets.first), throwsStateError);
      expect(state.tickets, isEmpty);
      db.failWrites = false;
      await state.addTicket(mockTickets.first);
      await state.addTicket(mockTickets.first);
      expect(state.tickets, hasLength(1));
      expect(db.records, hasLength(1));
    },
  );
  test(
    'status and consultation persist, failed updates leave memory unchanged',
    () async {
      final patients = FakePatientDatabase();
      final tickets = FakeTicketDatabase();
      final state = AppState(database: patients, ticketDatabase: tickets);
      for (final patient in mockPatients) {
        await state.addPatient(Patient.fromMap(patient.id, patient.toMap()));
      }
      final ticket = Ticket.fromMap(
        mockTickets.first.id,
        mockTickets.first.toMap(),
      );
      await state.addTicket(ticket);
      final original = ticket.status;
      tickets.failWrites = true;
      await expectLater(
        state.setStatus(ticket, TicketStatus.inConsultation),
        throwsStateError,
      );
      expect(ticket.status, original);
      tickets.failWrites = false;
      await state.setStatus(ticket, TicketStatus.inConsultation);
      await state.completeTicket(
        ticket,
        Consultation(
          date: DateTime(2026, 9, 23),
          doctor: ticket.doctor,
          complaint: ticket.complaint,
          diagnosis: 'Test diagnosis',
          treatment: 'Test treatment',
          prescription: 'None',
        ),
      );
      final restored = AppState(database: patients, ticketDatabase: tickets);
      await restored.loadClinicData();
      expect(restored.tickets.single.status, TicketStatus.completed);
      expect(restored.tickets.single.consultation!.diagnosis, 'Test diagnosis');
      expect(
        restored.patientFor(ticket.patientId).consultations.first.diagnosis,
        'Test diagnosis',
      );
    },
  );
}
