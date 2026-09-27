import 'dart:typed_data';

class LabAttachment {
  const LabAttachment({required this.name, this.bytes});
  final String name;
  final Uint8List? bytes;
}

class Consultation {
  Consultation({
    required this.date,
    required this.doctor,
    required this.complaint,
    required this.diagnosis,
    required this.treatment,
    required this.prescription,
  });
  final DateTime date;
  final String doctor;
  final String complaint;
  final String diagnosis;
  final String treatment;
  final String prescription;
}

class Patient {
  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    required this.address,
    required this.allergies,
    required this.conditions,
    required this.medicalHistory,
    required this.medications,
    required this.labs,
    required this.registeredAt,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.vaccinationStatus = 'Unknown',
    this.vaccines = const [],
    this.labAttachments = const [],
    List<Consultation>? consultations,
  }) : consultations = consultations ?? [];
  final String id,
      firstName,
      lastName,
      gender,
      phone,
      address,
      medicalHistory,
      labs;
  final DateTime dateOfBirth, registeredAt;
  final String emergencyContactName, emergencyContactPhone;
  final List<String> allergies, conditions, medications;
  final List<Consultation> consultations;
  final String vaccinationStatus;
  final List<String> vaccines;
  final List<LabAttachment> labAttachments;
  Map<String, dynamic> toMap() => {
    'firstName': firstName,
    'lastName': lastName,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'gender': gender,
    'phone': phone,
    'address': address,
    'allergies': allergies,
    'conditions': conditions,
    'medicalHistory': medicalHistory,
    'medications': medications,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'labs': labs,
    'vaccinationStatus': vaccinationStatus,
    'vaccines': vaccines,
    'labAttachments': labAttachments.map((file) => file.name).toList(),
    'registeredAt': registeredAt.toIso8601String(),
    'consultations': consultations
        .map(
          (c) => {
            'date': c.date.toIso8601String(),
            'doctor': c.doctor,
            'complaint': c.complaint,
            'diagnosis': c.diagnosis,
            'treatment': c.treatment,
            'prescription': c.prescription,
          },
        )
        .toList(),
  };

  factory Patient.fromMap(String id, Map<String, dynamic> data) => Patient(
    id: id,
    firstName: data['firstName'] as String,
    lastName: data['lastName'] as String,
    dateOfBirth: DateTime.parse(data['dateOfBirth'] as String),
    gender: data['gender'] as String,
    phone: data['phone'] as String,
    address: data['address'] as String,
    allergies: List<String>.from(data['allergies'] as List? ?? []),
    conditions: List<String>.from(data['conditions'] as List? ?? []),
    medicalHistory: data['medicalHistory'] as String? ?? '',
    medications: List<String>.from(data['medications'] as List? ?? []),
    emergencyContactName: data['emergencyContactName'] as String? ?? '',
    emergencyContactPhone: data['emergencyContactPhone'] as String? ?? '',
    labs: data['labs'] as String? ?? '',
    vaccinationStatus: data['vaccinationStatus'] as String? ?? 'Unknown',
    vaccines: List<String>.from(data['vaccines'] as List? ?? []),
    labAttachments: (data['labAttachments'] as List? ?? [])
        .map((name) => LabAttachment(name: name as String))
        .toList(),
    registeredAt: DateTime.parse(data['registeredAt'] as String),
    consultations: (data['consultations'] as List? ?? []).map((entry) {
      final c = Map<String, dynamic>.from(entry as Map);
      return Consultation(
        date: DateTime.parse(c['date'] as String),
        doctor: c['doctor'] as String,
        complaint: c['complaint'] as String,
        diagnosis: c['diagnosis'] as String,
        treatment: c['treatment'] as String,
        prescription: c['prescription'] as String,
      );
    }).toList(),
  );

  String get fullName => '$firstName $lastName';
  bool matchesSearch(String query) {
    final normalized = query.toLowerCase().replaceAll(',', ' ').trim();
    final dob =
        '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
    final searchable = '$lastName $firstName $id $phone $dob'.toLowerCase();
    return normalized.split(RegExp(r'\s+')).every(searchable.contains);
  }

  String get initials => '${firstName[0]}${lastName[0]}';
  int get age {
    final now = DateTime.now();
    var value = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      value--;
    }
    return value;
  }
}
