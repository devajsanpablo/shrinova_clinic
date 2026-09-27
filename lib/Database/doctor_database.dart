import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorOption {
  const DoctorOption(this.uid, this.username);
  final String uid;
  final String username;
}

abstract class DoctorDatabase {
  Future<List<DoctorOption>> loadDoctors();
}

class FirestoreDoctorDatabase implements DoctorDatabase {
  @override
  Future<List<DoctorOption>> loadDoctors() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctor')
        .get(const GetOptions(source: Source.server));
    final doctors = snapshot.docs
        .map(
          (doc) => DoctorOption(
            doc.id,
            (doc.data()['username'] as String? ?? '').trim(),
          ),
        )
        .where((doctor) => doctor.username.isNotEmpty)
        .toList();
    doctors.sort(
      (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
    );
    return doctors;
  }
}
