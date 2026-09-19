import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../screens/consultation_page.dart';
import '../screens/patient_profile_page.dart';
import 'common.dart';

class QueuePreview extends StatelessWidget {
  const QueuePreview({super.key, required this.role, required this.onAll});
  final UserRole role;
  final VoidCallback onAll;
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final visible = state.tickets
        .where(
          (t) =>
              t.status != TicketStatus.completed &&
              t.status != TicketStatus.cancelled &&
              (role == UserRole.staff || t.doctor == 'Dr. Adrian Reyes'),
        )
        .take(4)
        .toList();
    return SectionCard(
      title: "Today's queue",
      trailing: TextButton(onPressed: onAll, child: const Text('View all')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The next visits at a glance',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const EmptyState(
              title: 'All caught up',
              message: 'New visits will appear here.',
            ),
          ...visible.map((t) {
            final patient = state.patientFor(t.patientId);
            return Column(
              children: [
                const Divider(height: 1),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => role == UserRole.doctor
                          ? ConsultationPage(ticket: t)
                          : PatientProfilePage(patient: patient),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 45,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FB),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            t.queueNumber,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.fullName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.complaint,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 9),
                              Wrap(
                                spacing: 7,
                                runSpacing: 5,
                                children: [
                                  StatusBadge(status: t.status),
                                  if (t.priority != Priority.normal)
                                    PriorityBadge(priority: t.priority),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 19,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
