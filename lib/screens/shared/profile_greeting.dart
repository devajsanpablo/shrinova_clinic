import 'package:flutter/material.dart';

import '../../auth/staff/staff_auth_service.dart';
import '../../model/clinic_profile.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class ProfileGreeting extends StatefulWidget {
  const ProfileGreeting({
    super.key,
    required this.role,
    required this.greeting,
    this.loadProfile,
  });

  final UserRole role;
  final String greeting;
  final Future<ClinicProfile?> Function(UserRole)? loadProfile;

  @override
  State<ProfileGreeting> createState() => _ProfileGreetingState();
}

class _ProfileGreetingState extends State<ProfileGreeting> {
  late Future<ClinicProfile?> _profile = _load();

  Future<ClinicProfile?> _load() async {
    if (widget.loadProfile != null) return widget.loadProfile!(widget.role);
    final service = await StaffAuthService.initialize();
    return service.loadProfile(widget.role);
  }

  @override
  void didUpdateWidget(ProfileGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role ||
        oldWidget.loadProfile != widget.loadProfile) {
      _profile = _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ClinicProfile?>(
    future: _profile,
    builder: (context, snapshot) {
      final profile =
          snapshot.connectionState == ConnectionState.done && !snapshot.hasError
          ? snapshot.data
          : null;
      final firstName = profile?.firstName.trim() ?? '';
      return PageHeading(
        title: firstName.isEmpty
            ? widget.greeting
            : '${widget.greeting}, ${widget.role == UserRole.doctor ? 'Dr. ' : ''}$firstName',
        subtitle: "Here's how your clinic is doing today.",
      );
    },
  );
}
