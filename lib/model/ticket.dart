import 'patient.dart';

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
    this.doctorUid = '',
    required this.priority,
    required this.notes,
    required this.createdAt,
    this.status = TicketStatus.waiting,
    this.consultation,
  });
  final String id;
  String queueNumber;
  final String patientId,
      complaint,
      reason,
      bloodPressure,
      heartRate,
      temperature,
      oxygen;
  final List<String> symptoms;
  String doctor, notes;
  final String doctorUid;
  Priority priority;
  TicketStatus status;
  final DateTime createdAt;
  Consultation? consultation;

  Map<String, dynamic> toMap() => {
    'queueNumber': queueNumber,
    'patientId': patientId,
    'complaint': complaint,
    'reason': reason,
    'symptoms': symptoms,
    'bloodPressure': bloodPressure,
    'heartRate': heartRate,
    'temperature': temperature,
    'oxygen': oxygen,
    'doctor': doctor,
    'doctorUid': doctorUid,
    'notes': notes,
    'consultation': consultation == null
        ? null
        : {
            'date': consultation!.date.toIso8601String(),
            'doctor': consultation!.doctor,
            'complaint': consultation!.complaint,
            'diagnosis': consultation!.diagnosis,
            'treatment': consultation!.treatment,
            'prescription': consultation!.prescription,
          },
    'createdAt': createdAt.toIso8601String(),
    'priority': priority.name,
    'status': status.name,
  };

  factory Ticket.fromMap(String id, Map<String, dynamic> data) => Ticket(
    id: id,
    consultation: data['consultation'] == null
        ? null
        : Consultation(
            date: DateTime.parse(data['consultation']['date'] as String),
            doctor: data['consultation']['doctor'] as String,
            complaint: data['consultation']['complaint'] as String,
            diagnosis: data['consultation']['diagnosis'] as String,
            treatment: data['consultation']['treatment'] as String,
            prescription: data['consultation']['prescription'] as String,
          ),
    queueNumber: data['queueNumber'] as String,
    patientId: data['patientId'] as String,
    complaint: data['complaint'] as String,
    reason: data['reason'] as String,
    symptoms: List<String>.from(data['symptoms'] as List),
    bloodPressure: data['bloodPressure'] as String,
    heartRate: data['heartRate'] as String,
    temperature: data['temperature'] as String,
    oxygen: data['oxygen'] as String,
    doctor: data['doctor'] as String,
    doctorUid: data['doctorUid'] as String? ?? '',
    notes: data['notes'] as String,
    createdAt: DateTime.parse(data['createdAt'] as String),
    priority: Priority.values.byName(data['priority'] as String),
    status: TicketStatus.values.byName(data['status'] as String),
  );
}
