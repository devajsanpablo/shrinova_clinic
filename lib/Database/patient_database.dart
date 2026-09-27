import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/patient.dart';

abstract class PatientDatabase {
  Future<String> newPatientId();
  Future<Uint8List> loadLabImage(String patientId, int index);
  Future<List<Patient>> loadPatients();
  Future<void> savePatient(Patient patient);
}

class FirestorePatientDatabase implements PatientDatabase {
  CollectionReference<Map<String, dynamic>> get _patients =>
      FirebaseFirestore.instance.collection('patients');

  @override
  Future<String> newPatientId() async {
    final counter = FirebaseFirestore.instance.doc('counters/patients');
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(counter);
      final next = (snapshot.data()?['lastNumber'] as int? ?? 0) + 1;
      final id = 'PT-${next.toString().padLeft(2, '0')}';
      transaction.set(counter, {'lastNumber': next});
      return id;
    });
  }

  @override
  Future<Uint8List> loadLabImage(String patientId, int index) async {
    final file = await _patients
        .doc(patientId)
        .collection('labAttachments')
        .doc('$index')
        .get();
    return (file.data()!['bytes'] as Blob).bytes;
  }

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
    final batch = FirebaseFirestore.instance.batch();
    final reference = _patients.doc(patient.id);
    batch.set(reference, {
      ...patient.toMap(),
      'createdBy': user.uid,
      'consentConfirmedAt': FieldValue.serverTimestamp(),
    });
    for (var i = 0; i < patient.labAttachments.length; i++) {
      final attachment = patient.labAttachments[i];
      if (attachment.bytes != null) {
        batch.set(reference.collection('labAttachments').doc('$i'), {
          'name': attachment.name,
          'bytes': Blob(attachment.bytes!),
        });
      }
    }
    await batch.commit();
  }
}
