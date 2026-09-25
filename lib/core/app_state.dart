import 'package:flutter/material.dart';

import '../Database/patient_database.dart';
import '../Database/ticket_database.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  AppState({
    PatientDatabase? database,
    TicketDatabase? ticketDatabase,
    List<Patient>? initialPatients,
    List<Ticket>? initialTickets,
  }) : database = database ?? FirestorePatientDatabase(),
       ticketDatabase = ticketDatabase ?? FirestoreTicketDatabase(),
       patients = [...?initialPatients],
       tickets = [...?initialTickets];

  final PatientDatabase database;
  final TicketDatabase ticketDatabase;
  final List<Patient> patients;
  final List<Ticket> tickets;

  Future<void> loadPatients() async {
    final loaded = await database.loadPatients();
    patients
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<void> loadClinicData() async {
    final loadedPatients = await database.loadPatients();
    final loadedTickets = await ticketDatabase.loadTickets();
    patients
      ..clear()
      ..addAll(loadedPatients);
    tickets
      ..clear()
      ..addAll(loadedTickets);
    for (final ticket in tickets) {
      if (ticket.consultation != null) {
        patientFor(ticket.patientId).consultations
            .insert(0, ticket.consultation!);
      }
    }
    notifyListeners();
  }

  void clearSession() {
    patients.clear();
    tickets.clear();
    notifyListeners();
  }

  Patient patientFor(String id) => patients.firstWhere((p) => p.id == id);
  Future<void> addPatient(Patient patient) async {
    await database.savePatient(patient);
    patients.removeWhere((existing) => existing.id == patient.id);
    patients.insert(0, patient);
    notifyListeners();
  }

  Future<void> addTicket(Ticket ticket) async {
    await ticketDatabase.saveTicket(ticket);
    tickets.removeWhere((existing) => existing.id == ticket.id);
    tickets.insert(0, ticket);
    notifyListeners();
  }

  Future<void> setStatus(Ticket ticket, TicketStatus status) async {
    final updated = Ticket.fromMap(ticket.id, ticket.toMap())..status = status;
    await ticketDatabase.updateTicket(updated);
    ticket.status = status;
    notifyListeners();
  }

  Future<void> completeTicket(Ticket ticket, Consultation consultation) async {
    final updated = Ticket.fromMap(ticket.id, ticket.toMap())
      ..status = TicketStatus.completed
      ..consultation = consultation;
    await ticketDatabase.updateTicket(updated);
    ticket.consultation = consultation;
    ticket.status = TicketStatus.completed;
    patientFor(ticket.patientId).consultations.insert(0, consultation);
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null);
    return scope!.notifier!;
  }
}
