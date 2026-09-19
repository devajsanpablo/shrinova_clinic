import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  final List<Patient> patients = [...mockPatients];
  final List<Ticket> tickets = [...mockTickets];
  Patient patientFor(String id) => patients.firstWhere((p) => p.id == id);
  void addPatient(Patient patient) {
    patients.insert(0, patient);
    notifyListeners();
  }

  void addTicket(Ticket ticket) {
    tickets.insert(0, ticket);
    notifyListeners();
  }

  void setStatus(Ticket ticket, TicketStatus status) {
    ticket.status = status;
    notifyListeners();
  }

  void completeTicket(Ticket ticket, Consultation consultation) {
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
