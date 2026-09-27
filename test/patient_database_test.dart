import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/data/mock_data.dart';
import 'package:rmc_clinic_health/model/patient.dart';

import 'support/patient_database_fake.dart';

void main() {
  test('last-name-first search supports commas and case', () {
    final patient = mockPatients.first;
    expect(patient.matchesSearch(patient.lastName.toUpperCase()), isTrue);
    expect(
      patient.matchesSearch('${patient.lastName}, ${patient.firstName}'),
      isTrue,
    );
    expect(patient.matchesSearch('no-matching-name'), isFalse);
  });
  test('legacy patients default safely and new clinical fields persist', () {
    final data = mockPatients.first.toMap()
      ..remove('vaccinationStatus')
      ..remove('vaccines')
      ..remove('labAttachments');
    final legacy = Patient.fromMap('legacy', data);
    expect(legacy.vaccinationStatus, 'Unknown');
    expect(legacy.labAttachments, isEmpty);
    data.addAll({
      'vaccinationStatus': 'Yes',
      'vaccines': ['Influenza'],
      'labAttachments': ['result.jpg'],
    });
    final restored = Patient.fromMap('PT-01', data);
    expect(restored.toMap()['vaccines'], ['Influenza']);
    expect(restored.labAttachments.single.name, 'result.jpg');
  });
  test('production state starts without seeded patients or tickets', () {
    final state = AppState();
    expect(state.patients, isEmpty);
    expect(state.tickets, isEmpty);
  });

  test('patient fields survive saving and loading a fresh session', () async {
    final database = FakePatientDatabase();
    final first = AppState(database: database);
    await first.addPatient(mockPatients.first);
    final restored = AppState(database: database);
    await restored.loadPatients();
    expect(restored.patients.single.id, mockPatients.first.id);
    expect(restored.patients.single.toMap(), mockPatients.first.toMap());
  });

  test('failed writes do not insert patients and can be retried', () async {
    final database = FakePatientDatabase()..failWrites = true;
    final state = AppState(database: database);
    await expectLater(state.addPatient(mockPatients.first), throwsStateError);
    expect(state.patients, isEmpty);
    database.failWrites = false;
    await state.addPatient(mockPatients.first);
    await state.addPatient(mockPatients.first);
    expect(state.patients, hasLength(1));
  });
}
