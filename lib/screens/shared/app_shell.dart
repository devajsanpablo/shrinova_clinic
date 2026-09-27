import 'package:flutter/material.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/notification_service.dart';

import '../../core/theme.dart';
import '../../core/app_state.dart';
import '../../auth/staff/staff_auth_service.dart';
import '../../model/clinic_profile.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'dashboard_page.dart';
import 'login_page.dart';
import 'notifications_settings_pages.dart';
import 'patients_page.dart';
import 'queue_page.dart';
import 'feature_walkthrough_page.dart';
import 'register_patient_page.dart';
import 'ticket_form_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.role,
    this.profileLoader,
    this.initialIndex = 0,
  });
  final UserRole role;
  final Future<ClinicProfile?> Function()? profileLoader;
  final int initialIndex;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int index;
  late Future<ClinicProfile?> _profile;
  String _fallbackUserName = 'Account';
  int _unreadCount = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inbox;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ticketUpdates;
  final _navKeys = List.generate(5, (_) => GlobalKey());
  final _registerKey = GlobalKey();
  final _ticketKey = GlobalKey();
  final _formBackKey = GlobalKey();
  FeatureWalkthrough? _walkthrough;
  MaterialPageRoute<void>? _walkthroughForm;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    _profile = widget.profileLoader?.call() ?? _loadProfile();
  }

  Future<ClinicProfile?> _loadProfile() async {
    late final StaffAuthService service;
    late final User? user;
    try {
      service = await StaffAuthService.initialize();
      user = service.currentUser;
    } catch (_) {
      // Keep the workspace shell usable when Firebase is unavailable.
      return null;
    }
    if (mounted && user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startWalkthrough(user!.uid);
        }
      });
      _ticketUpdates = FirebaseFirestore.instance
          .collection('tickets')
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;
            AppStateScope.of(context).replaceTicketsFromLiveUpdate(
              snapshot.docs.map((doc) => Ticket.fromMap(doc.id, doc.data())),
            );
          }, onError: (Object _) {});
    }
    if (mounted && widget.role == UserRole.doctor && user != null) {
      AppStateScope.of(context).currentDoctorUid = user.uid;
      unawaited(
        ClinicNotifications.instance.start(user.uid, () {
          if (mounted) navigate(3);
        }),
      );
      _inbox = FirebaseFirestore.instance
          .collection('doctor')
          .doc(user.uid)
          .collection('notifications')
          .snapshots()
          .listen((snapshot) async {
            if (!mounted) return;
            final unread = snapshot.docs
                .where((doc) => doc.data()['read'] != true)
                .length;
            if (unread != _unreadCount) setState(() => _unreadCount = unread);
            try {
              await AppStateScope.of(context).loadClinicData();
            } catch (_) {
              // Inbox remains usable; opening a notification retries loading the queue.
            }
          }, onError: (Object _) {});
    }
    final displayName = user?.displayName?.trim() ?? '';
    final email = user?.email?.trim() ?? '';
    _fallbackUserName = displayName.isNotEmpty
        ? displayName
        : email.contains('@')
        ? email.split('@').first
        : 'Account';
    try {
      return await service.loadProfile(widget.role);
    } catch (_) {
      return null;
    }
  }

  void navigate(int value) => setState(() => index = value);

  Future<void> _openWalkthroughForm(Widget page) async {
    final route = MaterialPageRoute<void>(builder: (_) => page);
    _walkthroughForm = route;
    await Navigator.of(context).push(route);
    _walkthroughForm = null;
    // Registration can continue to the ticket page via pushReplacement.
    // Keep the tour paused until the user returns to the workspace.
    while (mounted && ModalRoute.of(context)?.isCurrent != true) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  void _closeWalkthroughForm() {
    final route = _walkthroughForm;
    _walkthroughForm = null;
    if (route?.isActive == true) Navigator.of(context).removeRoute(route!);
  }

  void _startWalkthrough(String uid) {
    if (_walkthrough != null) return;
    WalkthroughStep tab(int i, String title, String description) =>
        WalkthroughStep(
          target: _navKeys[i],
          title: title,
          description: description,
          onTap: () => navigate(i),
        );
    _walkthrough = FeatureWalkthrough(
      context: context,
      onEnd: _closeWalkthroughForm,
      steps: [
        tab(
          0,
          'Tap Overview',
          'This is your starting point for today’s visits, waiting patients and completed consultations.',
        ),
        if (widget.role == UserRole.staff) ...[
          WalkthroughStep(
            target: _registerKey,
            title: 'Tap Register patient',
            description: 'Start here when someone is new to your clinic. Tap this button to see the registration form.',
            onTap: () => _openWalkthroughForm(
              RegisterPatientPage(walkthroughBackKey: _formBackKey),
            ),
          ),
          WalkthroughStep(
            target: _ticketKey,
            title: 'Tap Create ticket',
            description: 'Use this button for a patient’s visit. Tap to see where you select a patient, record symptoms and assign a doctor.',
            onTap: () => _openWalkthroughForm(
              TicketFormPage(walkthroughBackKey: _formBackKey),
            ),
          ),
        ] else
          WalkthroughStep(
            target: _ticketKey,
            title: 'Tap Open my queue',
            description: 'This shortcut opens your assigned visits. Select a visit there to review symptoms, record consultation notes and complete the consultation.',
            onTap: () => navigate(1),
          ),
        tab(
          1,
          'Tap Patient queue',
          'Open the queue to track waiting, active and completed visits. Search and filter the list to find the visit you need.',
        ),
        tab(
          2,
          'Tap Patients',
          'Find patient records here. Open a patient to see contact details, medical background and consultation history.',
        ),
        if (widget.role == UserRole.doctor)
          tab(
            3,
            'Tap Notifications',
            'New visit assignments appear here. Open an alert to return to the queue.',
          ),
        tab(
          items.length - 1,
          'Tap Settings',
          'Your account and workspace preferences are here. Tap Settings to finish the tour.',
        ),
      ],
    );
    unawaited(_walkthrough!.showIfNeeded('${widget.role.name}_$uid'));
  }

  @override
  void dispose() {
    _walkthrough?.dispose();
    _inbox?.cancel();
    _ticketUpdates?.cancel();
    if (widget.role == UserRole.doctor) {
      unawaited(ClinicNotifications.instance.detach());
    }
    super.dispose();
  }

  late final pages = <Widget>[
    DashboardPage(
      role: widget.role,
      onNavigate: navigate,
      createTicketKey: _ticketKey,
      registerPatientKey: _registerKey,
    ),
    QueuePage(role: widget.role),
    const PatientsPage(),
    if (widget.role != UserRole.staff)
      NotificationsPage(onOpenQueue: () => navigate(1)),
    SettingsPage(role: widget.role, onLogout: logout),
  ];
  List<(String, IconData)> get items => [
    ('Overview', Icons.grid_view_rounded),
    ('Patient queue', Icons.view_list_outlined),
    ('Patients', Icons.people_alt_outlined),
    if (widget.role != UserRole.staff)
      ('Notifications', Icons.notifications_none_rounded),
    ('Settings', Icons.tune_rounded),
  ];
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
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final appState = AppStateScope.of(context);
    final queueCount = appState
        .todayTicketsForRole(widget.role)
        .where(
          (ticket) =>
              ticket.status == TicketStatus.waiting ||
              ticket.status == TicketStatus.sent ||
              ticket.status == TicketStatus.inConsultation,
        )
        .length;
    final desktop = width >= 1100;
    final tablet = width >= 700;
    final page = Reveal(key: ValueKey(index), child: pages[index]);
    return FutureBuilder<ClinicProfile?>(
      future: _profile,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.name.trim().isNotEmpty == true
            ? profile!.name
            : _fallbackUserName;
        final initials = profile?.initials ?? _initials(name);
        final detail = widget.role == UserRole.doctor
            ? (profile?.specialty.isNotEmpty == true
                  ? profile!.specialty
                  : 'Doctor')
            : 'Clinic staff';
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
                              horizontal: desktop ? 14 : 8,
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
                                    key: _navKeys[i],
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => navigate(i),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: desktop ? 16 : 0,
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: desktop
                                            ? MainAxisAlignment.start
                                            : MainAxisAlignment.center,
                                        children: [
                                          _NavBadge(
                                            icon: items[i].$2,
                                            count:
                                                items[i].$1 == 'Patient queue'
                                                ? queueCount
                                                : items[i].$1 == 'Notifications'
                                                ? _unreadCount
                                                : 0,
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
                                    PatientAvatar(
                                      initials: initials,
                                      radius: 19,
                                    ),
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
                                            detail,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
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
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    size: 20,
                                  ),
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
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
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
                                      items[index].$1,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.role == UserRole.staff
                                          ? 'Shrinovva · Staff'
                                          : 'Shrinovva · Doctor',
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
                              if (widget.role != UserRole.staff)
                                IconButton(
                                  tooltip: 'View notifications',
                                  onPressed: () => navigate(3),
                                  icon: _NavBadge(
                                    icon: Icons.notifications_none_rounded,
                                    count: _unreadCount,
                                    color: AppColors.muted,
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
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: PatientAvatar(
                                      initials: initials,
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
          bottomNavigationBar: tablet || keyboardOpen
              ? null
              : SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x220F172A),
                          blurRadius: 22,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: NavigationBar(
                      height: 68,
                      elevation: 0,
                      backgroundColor: Colors.white,
                      selectedIndex: index,
                      onDestinationSelected: navigate,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.onlyShowSelected,
                      destinations: items
                          .asMap()
                          .entries
                          .map(
                            (e) => NavigationDestination(
                              key: _navKeys[e.key],
                              icon: _NavBadge(
                                icon: e.value.$2,
                                count: e.value.$1 == 'Patient queue'
                                    ? queueCount
                                    : e.value.$1 == 'Notifications'
                                    ? _unreadCount
                                    : 0,
                              ),
                              label: switch (e.value.$1) {
                                'Patient queue' => 'Queue',
                                'Notifications' => 'Alerts',
                                _ => e.value.$1,
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'[\s._-]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return [
      parts.first,
      if (parts.length > 1) parts.last,
    ].map((part) => part[0].toUpperCase()).join();
  }
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.icon, this.count = 0, this.color});
  final IconData icon;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30,
    height: 28,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 3,
          bottom: 1,
          child: Icon(icon, size: 22, color: color),
        ),
        if (count > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFD92D20),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
