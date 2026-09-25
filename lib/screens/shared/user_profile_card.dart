import 'package:flutter/material.dart';

import '../../auth/staff/staff_auth_service.dart';
import '../../model/clinic_profile.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class UserProfileCard extends StatefulWidget {
  const UserProfileCard({super.key, required this.role, this.loadProfile});

  final UserRole role;
  final Future<ClinicProfile?> Function(UserRole)? loadProfile;

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  late Future<ClinicProfile?> _profile = _load();

  Future<ClinicProfile?> _load() async {
    if (widget.loadProfile != null) return widget.loadProfile!(widget.role);
    final service = await StaffAuthService.initialize();
    return service.loadProfile(widget.role);
  }

  @override
  void didUpdateWidget(UserProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role ||
        oldWidget.loadProfile != widget.loadProfile) {
      _profile = _load();
    }
  }

  void _reload() => setState(() {
    _profile = _load();
  });

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Profile',
    child: FutureBuilder<ClinicProfile?>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Expanded(child: Text('Loading your profile...')),
              ],
            ),
          );
        }
        final profile = snapshot.data;
        if (snapshot.hasError || profile == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.hasError
                    ? 'Unable to load your profile. Please try again.'
                    : 'Your profile could not be found. Contact your clinic administrator.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          );
        }
        final doctor = widget.role == UserRole.doctor;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PatientAvatar(initials: profile.initials, radius: 31),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty
                            ? 'Name not provided'
                            : profile.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(doctor ? 'Doctor' : 'Clinic Staff'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh profile',
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _detail('Email', profile.email),
            _detail('Phone', profile.phone),
            if (doctor) ...[
              _detail('Specialty', profile.specialty),
              _detail('License number', profile.licenseNumber),
            ] else
              _detail('Staff ID', profile.staffId),
          ],
        );
      },
    ),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text('$label: ${value.isEmpty ? 'Not provided' : value}'),
  );
}
