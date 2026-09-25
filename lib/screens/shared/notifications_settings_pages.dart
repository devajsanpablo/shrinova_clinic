import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'user_profile_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Consultation completed',
        'Q-021 • Ramon Garcia',
        Icons.check_circle_outline,
        AppColors.success,
      ),
      (
        'Ticket accepted by doctor',
        'Q-026 • Dr. Liza Mendoza',
        Icons.medical_services_outlined,
        AppColors.teal,
      ),
      (
        'Urgent ticket created',
        'Q-025 • Leo Villanueva',
        Icons.warning_amber_rounded,
        AppColors.warning,
      ),
      (
        'Ticket reassigned',
        'Q-019 • Assigned to Dr. Miguel Tan',
        Icons.swap_horiz_rounded,
        AppColors.primary,
      ),
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              title: 'Notifications',
              subtitle: 'Updates from today’s clinic activity',
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = items[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: n.$4.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(n.$3, color: n.$4),
                      ),
                      title: Text(
                        n.$1,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('${n.$2}\n${i * 12 + 4} minutes ago'),
                      isThreeLine: true,
                      trailing: i < 2
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.role, required this.onLogout});
  final UserRole role;
  final VoidCallback onLogout;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool push = true, email = false, compact = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              title: 'Profile & settings',
              subtitle: 'Your account details and workspace preferences',
            ),
            const SizedBox(height: 20),
            UserProfileCard(role: widget.role),
            if (MediaQuery.sizeOf(context).width < 700) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 15),
            SectionCard(
              title: 'Notifications',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('In-app notifications'),
                    subtitle: const Text(
                      'Ticket updates and consultation alerts',
                    ),
                    value: push,
                    onChanged: (v) => setState(() => push = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Email summaries'),
                    subtitle: const Text(
                      'Receive a simulated daily activity summary',
                    ),
                    value: email,
                    onChanged: (v) => setState(() => email = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            SectionCard(
              title: 'Appearance & session',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Compact layout'),
                    subtitle: const Text(
                      'Show more information on larger screens',
                    ),
                    value: compact,
                    onChanged: (v) => setState(() => compact = v),
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.timer_outlined),
                    title: Text('Automatic logout'),
                    subtitle: Text(
                      'After 15 minutes of inactivity (visual concept only)',
                    ),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.history),
                    title: Text('Audit trail'),
                    subtitle: Text(
                      'Actions in this static demo are not stored permanently',
                    ),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
