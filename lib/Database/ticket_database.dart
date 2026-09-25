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
    // A lost acknowledgement can be retried without creating another ticket.
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) return;
      transaction.set(ref, {
        ...ticket.toMap(),
        'createdBy': user.uid,
        'savedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> updateTicket(Ticket ticket) => _tickets.doc(ticket.id).update({
    'status': ticket.status.name,
    'consultation': ticket.toMap()['consultation'],
  });
}
