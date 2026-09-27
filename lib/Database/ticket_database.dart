import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/ticket.dart';

abstract class TicketDatabase {
  String newTicketId();
  Future<List<Ticket>> loadTickets();
  Future<void> saveTicket(Ticket ticket);
  Future<void> updateTicket(Ticket ticket);
}

class FirestoreTicketDatabase implements TicketDatabase {
  CollectionReference<Map<String, dynamic>> get _tickets =>
      FirebaseFirestore.instance.collection('tickets');
  @override
  String newTicketId() => _tickets.doc().id;
  @override
  Future<List<Ticket>> loadTickets() async {
    final snapshot = await _tickets
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.server));
    return snapshot.docs
        .map((doc) => Ticket.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> saveTicket(Ticket ticket) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Clinic sign-in is required.');
    final ref = _tickets.doc(ticket.id);
    final day = _queueDay(ticket.createdAt);
    final counterRef = FirebaseFirestore.instance
        .collection('queueCounters')
        .doc(day);
    var existingCount = 0;
    final knownCounter = await counterRef.get(
      const GetOptions(source: Source.server),
    );
    if (!knownCounter.exists) {
      final localDate = ticket.createdAt.toLocal();
      final nextDay = DateTime(
        localDate.year,
        localDate.month,
        localDate.day + 1,
      );
      final nextDayKey =
          '${nextDay.year}-${nextDay.month.toString().padLeft(2, '0')}-${nextDay.day.toString().padLeft(2, '0')}';
      final existingToday = await _tickets
          .where('createdAt', isGreaterThanOrEqualTo: day)
          .where('createdAt', isLessThan: nextDayKey)
          .get(const GetOptions(source: Source.server));
      existingCount = existingToday.docs.length;
    } else {
      existingCount = knownCounter.data()?['count'] as int? ?? 0;
    }
    var assignedQueueNumber = ticket.queueNumber;
    // A lost acknowledgement can be retried without creating another ticket.
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        assignedQueueNumber =
            existing.data()?['queueNumber'] as String? ?? ticket.queueNumber;
        return;
      }
      final counter = await transaction.get(counterRef);
      final previousCount = counter.data()?['count'] as int? ?? existingCount;
      final nextNumber = previousCount + 1;
      assignedQueueNumber = 'No.$nextNumber';
      transaction.set(counterRef, {'count': nextNumber});
      final ticketData = ticket.toMap()..['queueNumber'] = assignedQueueNumber;
      transaction.set(ref, {
        ...ticketData,
        'createdBy': user.uid,
        'savedAt': FieldValue.serverTimestamp(),
      });
    });
    ticket.queueNumber = assignedQueueNumber;
  }

  String _queueDay(DateTime timestamp) {
    final date = timestamp.toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Future<void> updateTicket(Ticket ticket) async {
    final ticketRef = _tickets.doc(ticket.id);
    final consultation = ticket.toMap()['consultation'];
    if (ticket.status != TicketStatus.completed || consultation == null) {
      await ticketRef.update({
        'status': ticket.status.name,
        'consultation': consultation,
      });
      return;
    }

    final historyRef = FirebaseFirestore.instance
        .collection('patients')
        .doc(ticket.patientId)
        .collection('checkupHistory')
        .doc(ticket.id);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final history = await transaction.get(historyRef);
      transaction.update(ticketRef, {
        'status': ticket.status.name,
        'consultation': consultation,
      });
      if (!history.exists) {
        transaction.set(historyRef, {
          'ticketId': ticket.id,
          'queueNumber': ticket.queueNumber,
          'consultation': consultation,
          'recordedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
