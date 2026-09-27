import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/core/app_state.dart';
import 'package:rmc_clinic_health/core/theme.dart';
import 'package:rmc_clinic_health/models/models.dart';
import 'package:rmc_clinic_health/widgets/queue_preview.dart';

import '../tool/load_app_fonts.dart';
import 'support/patient_database_fake.dart';

void main() {
  testWidgets('today queue uses doctor UID and updates when a ticket is sent', (
    tester,
  ) async {
    final state = testAppState()..currentDoctorUid = 'signed-in-doctor';
    final base = state.tickets.first.toMap();
    Ticket ticket(String id, String uid, String name, TicketStatus status) =>
        Ticket.fromMap(id, {
          ...base,
          'doctorUid': uid,
          'doctor': name,
          'complaint': id,
          'status': status.name,
        });
    state.tickets
      ..clear()
      ..addAll([
        ticket('other-doctor', 'other', 'Dr. Adrian Reyes', TicketStatus.sent),
        ticket(
          'unsent-draft',
          'signed-in-doctor',
          'actual.username',
          TicketStatus.draft,
        ),
        ticket(
          'closed-visit',
          'signed-in-doctor',
          'actual.username',
          TicketStatus.completed,
        ),
      ]);
    var openedQueue = false;
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: QueuePreview(
                role: UserRole.doctor,
                onAll: () => openedQueue = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async => loadAppFonts());
    await tester.pumpAndSettle();
    expect(find.text('All caught up'), findsOneWidget);
    await state.addTicket(
      ticket(
        'new-assigned-visit',
        'signed-in-doctor',
        'actual.username',
        TicketStatus.sent,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('new-assigned-visit'), findsOneWidget);
    expect(find.text('other-doctor'), findsNothing);
    expect(find.text('unsent-draft'), findsNothing);
    expect(find.text('closed-visit'), findsNothing);
    await tester.tap(find.text('View all'));
    expect(openedQueue, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('staff retain all tickets and doctors without a session see none', () {
    final state = testAppState();
    expect(state.ticketsForRole(UserRole.staff).length, state.tickets.length);
    expect(state.ticketsForRole(UserRole.doctor), isEmpty);
  });
}
