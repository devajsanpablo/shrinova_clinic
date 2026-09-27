import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_state.dart';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'user_profile_card.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.onOpenQueue});
  final VoidCallback? onOpenQueue;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const _pageSize = 15;
  int _visibleCount = _pageSize;

  String _timestamp(dynamic value) {
    final date = value is Timestamp
        ? value.toDate()
        : value is String
        ? DateTime.tryParse(value)
        : null;
    if (date == null) return '';
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final meridiem = local.hour < 12 ? 'AM' : 'PM';
    return '${shortDate(local)} · $hour:$minute $meridiem';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Sign in to see your notifications.'));
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            title: 'Notifications',
            subtitle: 'Consultation tickets assigned to you',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('doctor')
                  .doc(uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .limit(_visibleCount)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Unable to load notifications. Check your connection.',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!.docs;
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notifications yet. New assigned tickets will appear here.',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount:
                      items.length + (items.length == _visibleCount ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == items.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _visibleCount += _pageSize),
                            icon: const Icon(Icons.expand_more),
                            label: const Text('Load more'),
                          ),
                        ),
                      );
                    }
                    final item = items[i];
                    final data = item.data();
                    final read = data['read'] == true;
                    return ListTile(
                      shape: const Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                      leading: Icon(
                        read
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        data['title'] as String? ?? 'New consultation ticket',
                        style: TextStyle(
                          fontWeight: read ? FontWeight.w500 : FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        [
                          data['body'] as String? ??
                              'Open your queue to review this ticket.',
                          _timestamp(data['createdAt']),
                        ].where((part) => part.isNotEmpty).join('\n'),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        try {
                          await AppStateScope.of(context).loadClinicData();
                          await item.reference.update({'read': true});
                          if (context.mounted) widget.onOpenQueue?.call();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Unable to open the queue. Please retry.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.role, required this.onLogout});
  final UserRole role;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final spacing = width < 600 ? 18.0 : 28.0;
    return SafeArea(
      bottom: width >= 700,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(spacing, spacing, spacing, spacing + 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              title: 'Profile & settings',
              subtitle: 'Your account details',
            ),
            const SizedBox(height: 20),
            UserProfileCard(role: role),
            if (MediaQuery.sizeOf(context).width < 700) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
