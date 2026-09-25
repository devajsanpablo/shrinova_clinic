import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/patient.dart';

abstract class PatientDatabase {
  String newPatientId();
  Future<List<Patient>> loadPatients();
  Future<void> savePatient(Patient patient);
}

class FirestorePatientDatabase implements PatientDatabase {
  CollectionReference<Map<String, dynamic>> get _patients =>
      FirebaseFirestore.instance.collection('patients');

  @override
  String newPatientId() => _patients.doc().id;

  @override
  Future<List<Patient>> loadPatients() async {
    final snapshot = await _patients
        .orderBy('registeredAt', descending: true)
        .get(const GetOptions(source: Source.server));
    return snapshot.docs
        .map((doc) => Patient.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> savePatient(Patient patient) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Clinic sign-in is required.');
    await _patients.doc(patient.id).set({
      ...patient.toMap(),
      'createdBy': user.uid,
      'consentConfirmedAt': FieldValue.serverTimestamp(),
    });
  }
}
