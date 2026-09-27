import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../doctor/consultation_page.dart';
import 'patient_profile_page.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key, required this.role});
  final UserRole role;
  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  String filter = 'All', query = '';
  final _searchKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final keyboardOpen = View.of(context).viewInsets.bottom > 0;
    final visibleHeight =
        MediaQuery.sizeOf(context).height -
        View.of(context).viewInsets.bottom / View.of(context).devicePixelRatio;
    final state = AppStateScope.of(context);
    final all = state.todayTicketsForRole(widget.role).toList()
      ..sort((a, b) {
        final aSequence = _queueSequence(a.queueNumber);
        final bSequence = _queueSequence(b.queueNumber);
        if (aSequence != null && bSequence != null) {
          return aSequence.compareTo(bSequence);
        }
        if (aSequence != null) return 1;
        if (bSequence != null) return -1;
        final arrivalOrder = a.createdAt.compareTo(b.createdAt);
        return arrivalOrder != 0 ? arrivalOrder : a.id.compareTo(b.id);
      });
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
    final waitingCount = all
        .where(
          (ticket) =>
              ticket.status == TicketStatus.waiting ||
              ticket.status == TicketStatus.sent,
        )
        .length;
    final counts = <String, int>{
      'All': all.length,
      'Waiting': waitingCount,
      'In Consultation': all
          .where((ticket) => ticket.status == TicketStatus.inConsultation)
          .length,
      'Completed': all
          .where((ticket) => ticket.status == TicketStatus.completed)
          .length,
      'Urgent': all
          .where((ticket) => ticket.priority != Priority.normal)
          .length,
    };
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
        vertical: keyboardOpen
            ? 8
            : MediaQuery.sizeOf(context).width < 600
            ? 18
            : 28,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!keyboardOpen) ...[
                PageHeading(
                  title: widget.role == UserRole.staff
                      ? "Today's queue"
                      : 'Your patient queue',
                  subtitle: 'First come, first served. Priority labels are for triage; they do not change queue order.',
                ),
                const SizedBox(height: 22),
              ],
              TextField(
                key: _searchKey,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                  hintText: 'Search patient, queue number, or complaint',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              if (!keyboardOpen) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        [
                              'All',
                              'Waiting',
                              'In Consultation',
                              'Completed',
                              'Urgent',
                            ]
                            .map(
                              (label) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  showCheckmark: false,
                                  color: WidgetStateProperty.resolveWith((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return const Color(0xFFE4E8EF);
                                    }
                                    return const Color(0xFFF0F2F5);
                                  }),
                                  label: Text(
                                    '${label == 'All' ? 'All visits' : label} (${counts[label]})',
                                    style: TextStyle(
                                      color: filter == label
                                          ? AppColors.ink
                                          : AppColors.muted,
                                    ),
                                  ),
                                  selected: filter == label,
                                  onSelected: (_) =>
                                      setState(() => filter = label),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${tickets.length} ${tickets.length == 1 ? 'visit' : 'visits'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: keyboardOpen
                    ? (visibleHeight.clamp(0.0, constraints.maxHeight) -
                              MediaQuery.textScalerOf(context).scale(80))
                          .clamp(48.0, 500.0)
                    : constraints.maxHeight < 500
                    ? 300
                    : constraints.maxHeight - 250,
                child: tickets.isEmpty
                    ? keyboardOpen
                          ? const Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('No visits found'),
                              ),
                            )
                          : const SingleChildScrollView(
                              child: EmptyState(
                                title: 'No visits found',
                                message: 'Try another search or choose a different filter.',
                              ),
                            )
                    : ListView.separated(
                        itemCount: tickets.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final t = tickets[i];
                          final p = state.patientFor(t.patientId);
                          final finished =
                              t.status == TicketStatus.completed ||
                              t.status == TicketStatus.cancelled;
                          void view() => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => widget.role == UserRole.doctor
                                  ? ConsultationPage(ticket: t)
                                  : PatientProfilePage(patient: p),
                            ),
                          );
                          Future<void> start() async {
                            try {
                              await state.setStatus(
                                t,
                                TicketStatus.inConsultation,
                              );
                              if (!context.mounted) return;
                              view();
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not start consultation. Please retry.',
                                  ),
                                ),
                              );
                            }
                          }

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: LayoutBuilder(
                                builder: (_, c) {
                                  final narrow = c.maxWidth < 650;
                                  final summary = Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 7,
                                              children: [
                                                StatusBadge(status: t.status),
                                                PriorityBadge(
                                                  priority: t.priority,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                  final details = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      widget.role == UserRole.doctor &&
                                          !finished
                                      ? FilledButton.icon(
                                          onPressed: start,
                                          icon: const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 17,
                                          ),
                                          label: Text(
                                            t.status ==
                                                    TicketStatus.inConsultation
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
        ),
      ),
    );
  }

  int? _queueSequence(String queueNumber) {
    final match = RegExp(r'^No\.(\d+)$').firstMatch(queueNumber);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
