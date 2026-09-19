import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/care_banner.dart';
import '../widgets/queue_preview.dart';
import '../widgets/motion.dart';
import 'patient_profile_page.dart';
import 'register_patient_page.dart';
import 'ticket_form_page.dart';
import 'patients_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.role,
    required this.onNavigate,
  });
  final UserRole role;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final tickets = state.tickets
        .where((t) => role == UserRole.staff || t.doctor == 'Dr. Adrian Reyes')
        .toList();
    final waiting = tickets
        .where(
          (t) =>
              t.status == TicketStatus.waiting || t.status == TicketStatus.sent,
        )
        .length;
    final active = tickets
        .where((t) => t.status == TicketStatus.inConsultation)
        .length;
    final done = tickets
        .where((t) => t.status == TicketStatus.completed)
        .length;
    final urgent = tickets
        .where(
          (t) =>
              t.priority != Priority.normal &&
              t.status != TicketStatus.completed &&
              t.status != TicketStatus.cancelled,
        )
        .length;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 18 : 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeading(
                title:
                    '$greeting, ${role == UserRole.staff ? 'Angela' : 'Dr. Reyes'}',
                subtitle: "Here's how your clinic is doing today.",
              ),
              const SizedBox(height: 24),
              Reveal(
                child: CareBanner(
                  doctor: role == UserRole.doctor,
                  onPrimary: () => role == UserRole.doctor
                      ? onNavigate(1)
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TicketFormPage(),
                          ),
                        ),
                  onSecondary: () => role == UserRole.doctor
                      ? onNavigate(1)
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPatientPage(),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Text(
                    'Today at a glance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  const Icon(Icons.circle, size: 6, color: AppColors.teal),
                  const SizedBox(width: 6),
                  const Text('Live overview', style: TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 13),
              LayoutBuilder(
                builder: (_, c) {
                  final count = c.maxWidth >= 950
                      ? 5
                      : c.maxWidth >= 630
                      ? 3
                      : 2;
                  final width = (c.maxWidth - (count - 1) * 12) / count;
                  final stats = [
                    (
                      'Visits today',
                      '${tickets.length}',
                      Icons.people_outline,
                      AppColors.primary,
                    ),
                    (
                      'Waiting',
                      '$waiting',
                      Icons.schedule_rounded,
                      AppColors.warning,
                    ),
                    (
                      'In consultation',
                      '$active',
                      Icons.medical_services_outlined,
                      AppColors.teal,
                    ),
                    (
                      'Completed',
                      '$done',
                      Icons.task_alt_rounded,
                      AppColors.success,
                    ),
                    (
                      'Needs attention',
                      '$urgent',
                      Icons.priority_high_rounded,
                      const Color(0xFFB77B28),
                    ),
                  ];
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(stats.length, (i) {
                      final s = stats[i];
                      return SizedBox(
                        width: width,
                        child: Reveal(
                          delay: 60 * i,
                          child: StatCard(
                            label: s.$1,
                            value: s.$2,
                            icon: s.$3,
                            tint: s.$4,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (_, c) {
                  final queue = QueuePreview(
                    role: role,
                    onAll: () => onNavigate(1),
                  );
                  final patients = _RecentPatients(
                    role: role,
                    onAll: () {
                      if (role == UserRole.staff) {
                        onNavigate(2);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: const Text('Patients')),
                              body: const SafeArea(child: PatientsPage()),
                            ),
                          ),
                        );
                      }
                    },
                  );
                  return c.maxWidth > 850
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: queue),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: patients),
                          ],
                        )
                      : Column(
                          children: [
                            queue,
                            const SizedBox(height: 18),
                            patients,
                          ],
                        );
                },
              ),
              const SizedBox(height: 22),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Thoughtfully organized. Patient care, simplified.',
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentPatients extends StatelessWidget {
  const _RecentPatients({required this.role, required this.onAll});
  final UserRole role;
  final VoidCallback onAll;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Patient directory',
    trailing: TextButton(onPressed: onAll, child: const Text('View all')),
    child: Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onAll,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 18, color: AppColors.muted),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Find a patient', style: TextStyle(fontSize: 12)),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...AppStateScope.of(context).patients
            .take(4)
            .map(
              (p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: PatientAvatar(initials: p.initials, radius: 21),
                title: Text(
                  p.fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                subtitle: Text(
                  '${p.age} years · ${p.gender}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientProfilePage(patient: p),
                  ),
                ),
              ),
            ),
      ],
    ),
  );
}
