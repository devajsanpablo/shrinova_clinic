import 'package:rmc_clinic_health/Database/ticket_database.dart';
import 'package:rmc_clinic_health/model/ticket.dart';

class FakeTicketDatabase implements TicketDatabase {
  final Map<String, Map<String, dynamic>> records = {};
  bool failWrites = false;
  int _nextId = 0;
  @override
  String newTicketId() => 'test-ticket-${_nextId++}';
  @override
  Future<List<Ticket>> loadTickets() async => records.entries
      .map((entry) => Ticket.fromMap(entry.key, entry.value))
      .toList();
  @override
  Future<void> saveTicket(Ticket ticket) async {
    if (failWrites) throw StateError('Write failed');
    records.putIfAbsent(ticket.id, ticket.toMap);
  }

  @override
  Future<void> updateTicket(Ticket ticket) async {
    if (failWrites) throw StateError('Write failed');
    records[ticket.id] = ticket.toMap();
  }
}
