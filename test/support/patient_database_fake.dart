import 'ticket_database_fake.dart';

import 'package:rmc_clinic_health/Database/patient_database.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/data/mock_data.dart';
import 'package:rmc_clinic_health/model/patient.dart';

class FakePatientDatabase implements PatientDatabase {
  final Map<String, Map<String, dynamic>> records = {};
  bool failWrites = false;
  int _nextId = 0;
  @override
  String newPatientId() => 'test-patient-${_nextId++}';
  @override
  Future<List<Patient>> loadPatients() async => records.entries
      .map((entry) => Patient.fromMap(entry.key, entry.value))
      .toList();
  @override
  Future<void> savePatient(Patient patient) async {
    if (failWrites) throw StateError('Write failed');
    records[patient.id] = patient.toMap();
  }
}

AppState testAppState() => AppState(
  database: FakePatientDatabase(),
  ticketDatabase: FakeTicketDatabase(),
  initialPatients: mockPatients,
  initialTickets: mockTickets,
);
