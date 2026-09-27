import 'package:rmc_clinic_health/Database/doctor_database.dart';

import 'dart:typed_data';

import 'ticket_database_fake.dart';

import 'package:rmc_clinic_health/Database/patient_database.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/data/mock_data.dart';
import 'package:rmc_clinic_health/model/patient.dart';

class FakePatientDatabase implements PatientDatabase {
  final Map<String, Map<String, dynamic>> records = {};
  bool failWrites = false;
  int _nextId = 1;
  @override
  Future<String> newPatientId() async =>
      'PT-${(_nextId++).toString().padLeft(2, '0')}';
  @override
  Future<Uint8List> loadLabImage(String patientId, int index) async =>
      throw UnimplementedError();
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

class FakeDoctorDatabase implements DoctorDatabase {
  @override
  Future<List<DoctorOption>> loadDoctors() async => [
    const DoctorOption('doctor-test', 'Dr. Test'),
  ];
}

AppState testAppState() => AppState(
  database: FakePatientDatabase(),
  doctorDatabase: FakeDoctorDatabase(),
  ticketDatabase: FakeTicketDatabase(),
  initialPatients: mockPatients,
  initialTickets: mockTickets,
  refreshQueueAtMidnight: false,
);
