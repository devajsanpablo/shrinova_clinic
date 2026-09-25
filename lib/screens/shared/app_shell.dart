import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/app_state.dart';
import '../../auth/staff/staff_auth_service.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'dashboard_page.dart';
import 'login_page.dart';
import 'notifications_settings_pages.dart';
import 'patients_page.dart';
import 'queue_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.role});
  final UserRole role;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  void navigate(int value) => setState(() => index = value);
  late final pages = <Widget>[
    DashboardPage(role: widget.role, onNavigate: navigate),
    QueuePage(role: widget.role),
    const PatientsPage(),
    const NotificationsPage(),
    SettingsPage(role: widget.role, onLogout: logout),
  ];
  List<(String, IconData)> get items => [
    ('Overview', Icons.grid_view_rounded),
    ('Patient queue', Icons.view_list_outlined),
    ('Patients', Icons.people_alt_outlined),
    ('Notifications', Icons.notifications_none_rounded),
    ('Settings', Icons.tune_rounded),
  ];
  String get name =>
      widget.role == UserRole.staff ? 'Angela Ramos' : 'Dr. Adrian Reyes';
  Future<void> logout() async {
    try {
      await (await StaffAuthService.initialize()).signOut();
      if (!mounted) return;
      AppStateScope.of(context).clearSession();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 1100;
    final tablet = width >= 700;
    final page = Reveal(key: ValueKey(index), child: pages[index]);
    return Scaffold(
      body: Row(
        children: [
          if (tablet)
            Container(
              width: desktop ? 238 : 84,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: desktop ? 22 : 16,
                      ),
                      child: ClinicMark(compact: !desktop),
                    ),
                    if (desktop)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(26, 8, 24, 18),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'WORKSPACE',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 14 : 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Tooltip(
                            message: desktop ? '' : items[i].$1,
                            child: Material(
                              color: index == i
                                  ? const Color(0xFFEFF4FF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => navigate(i),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        items[i].$2,
                                        size: 21,
                                        color: index == i
                                            ? AppColors.primary
                                            : AppColors.muted,
                                      ),
                                      if (desktop) ...[
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            items[i].$1,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: index == i
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: index == i
                                                  ? AppColors.primary
                                                  : AppColors.muted,
                                            ),
                                          ),
                                        ),
                                        if (index == i)
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (desktop)
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F7F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.favorite_outline,
                                color: AppColors.teal,
                                size: 22,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Care starts with you.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'A little organization. More time for your patients.',
                                style: TextStyle(fontSize: 11, height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      child: desktop
                          ? Row(
                              children: [
                                const PatientAvatar(initials: 'AR', radius: 19),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      Text(
                                        widget.role == UserRole.staff
                                            ? 'Clinic staff'
                                            : 'Internal medicine',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Sign out',
                                  onPressed: logout,
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                  ),
                                ),
                              ],
                            )
                          : IconButton(
                              tooltip: 'Sign out',
                              onPressed: logout,
                              icon: const Icon(Icons.logout_rounded, size: 20),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tablet ? 28 : 18,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          if (!tablet) ...[
                            const ClinicMark(compact: true),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shrinovva Homeophatic',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.role == UserRole.staff
                                      ? 'Staff workspace'
                                      : 'Doctor workspace',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (width >= 900) ...[
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 15,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              shortDate(DateTime.now()),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 24),
                          ],
                          IconButton(
                            tooltip: 'View notifications',
                            onPressed: () => navigate(3),
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              size: 22,
                            ),
                          ),
                          if (!tablet)
                            PopupMenuButton<String>(
                              tooltip: 'Account menu',
                              onSelected: (value) {
                                if (value == 'logout') {
                                  logout();
                                } else {
                                  navigate(items.length - 1);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'settings',
                                  child: Text(name),
                                ),
                                const PopupMenuItem(
                                  value: 'logout',
                                  child: Text('Sign out'),
                                ),
                              ],
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: PatientAvatar(
                                  initials: 'AR',
                                  radius: 17,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: page),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: tablet
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: navigate,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: items
                  .map(
                    (e) => NavigationDestination(
                      icon: Icon(e.$2, size: 22),
                      label: e.$1 == 'Patient queue' ? 'Queue' : e.$1,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
