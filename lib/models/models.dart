enum UserRole { staff, doctor }

enum TicketStatus { draft, waiting, sent, inConsultation, completed, cancelled }

enum Priority { normal, urgent, emergency }

extension TicketStatusLabel on TicketStatus {
  String get label => switch (this) {
    TicketStatus.draft => 'Draft',
    TicketStatus.waiting => 'Waiting',
    TicketStatus.sent => 'Sent to Doctor',
    TicketStatus.inConsultation => 'In Consultation',
    TicketStatus.completed => 'Completed',
    TicketStatus.cancelled => 'Cancelled',
  };
}

extension PriorityLabel on Priority {
  String get label => name[0].toUpperCase() + name.substring(1);
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
  String get fullName => '$firstName $lastName';
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

class Ticket {
  Ticket({
    required this.id,
    required this.queueNumber,
    required this.patientId,
    required this.complaint,
    required this.reason,
    required this.symptoms,
    required this.bloodPressure,
    required this.heartRate,
    required this.temperature,
    required this.oxygen,
    required this.doctor,
    required this.priority,
    required this.notes,
    required this.createdAt,
    this.status = TicketStatus.waiting,
  });
  final String id,
      queueNumber,
      patientId,
      complaint,
      reason,
      bloodPressure,
      heartRate,
      temperature,
      oxygen;
  final List<String> symptoms;
  String doctor, notes;
  Priority priority;
  TicketStatus status;
  final DateTime createdAt;
}
