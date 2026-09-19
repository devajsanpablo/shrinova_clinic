import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'consultation_page.dart';
import 'patient_profile_page.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key, required this.role});
  final UserRole role;
  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  String filter = 'All', query = '';
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final all = state.tickets
        .where(
          (t) =>
              widget.role == UserRole.staff || t.doctor == 'Dr. Adrian Reyes',
        )
        .toList();
    final tickets = all.where((t) {
      final matches =
          filter == 'All' ||
          t.status.label == filter ||
          (filter == 'Waiting' && t.status == TicketStatus.sent) ||
          (filter == 'Urgent' && t.priority != Priority.normal);
      return matches &&
          '${state.patientFor(t.patientId).fullName} ${t.queueNumber} ${t.complaint}'
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();
    return Padding(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 18 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: widget.role == UserRole.staff
                ? "Today's queue"
                : 'Your patient queue',
            subtitle: 'Keep every visit moving, from arrival to follow-up.',
          ),
          const SizedBox(height: 22),
          TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              hintText: 'Search patient, queue number, or complaint',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  ['All', 'Waiting', 'In Consultation', 'Completed', 'Urgent']
                      .map(
                        (label) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Text(
                              label == 'All'
                                  ? 'All visits (${all.length})'
                                  : label,
                            ),
                            selected: filter == label,
                            onSelected: (_) => setState(() => filter = label),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${tickets.length} ${tickets.length == 1 ? 'visit' : 'visits'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tickets.isEmpty
                ? const SingleChildScrollView(
                    child: EmptyState(
                      title: 'No visits found',
                      message:
                          'Try another search or choose a different filter.',
                    ),
                  )
                : ListView.separated(
                    itemCount: tickets.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final t = tickets[i];
                      final p = state.patientFor(t.patientId);
                      final finished =
                          t.status == TicketStatus.completed ||
                          t.status == TicketStatus.cancelled;
                      void view() => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              widget.role == UserRole.doctor && !finished
                              ? ConsultationPage(ticket: t)
                              : PatientProfilePage(patient: p),
                        ),
                      );
                      void start() {
                        state.setStatus(t, TicketStatus.inConsultation);
                        view();
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: LayoutBuilder(
                            builder: (_, c) {
                              final narrow = c.maxWidth < 650;
                              final summary = Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PatientAvatar(
                                    initials: p.initials,
                                    radius: 24,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 5,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              p.fullName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            Text(
                                              t.queueNumber,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          t.complaint,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 7,
                                          children: [
                                            StatusBadge(status: t.status),
                                            PriorityBadge(priority: t.priority),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                              final details = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.doctor,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    finished
                                        ? 'Visit closed'
                                        : '${DateTime.now().difference(t.createdAt).inMinutes} min since arrival',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              );
                              final action =
                                  widget.role == UserRole.doctor && !finished
                                  ? FilledButton.icon(
                                      onPressed: start,
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 17,
                                      ),
                                      label: Text(
                                        t.status == TicketStatus.inConsultation
                                            ? 'Continue visit'
                                            : 'Start consultation',
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: view,
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 17,
                                      ),
                                      label: const Text('View patient'),
                                    );
                              if (narrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    summary,
                                    const Divider(height: 28),
                                    details,
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: action,
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(flex: 3, child: summary),
                                  const SizedBox(width: 20),
                                  Expanded(flex: 2, child: details),
                                  const SizedBox(width: 12),
                                  action,
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
