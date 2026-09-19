import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import 'clinic_art.dart';

class ClinicMark extends StatelessWidget {
  const ClinicMark({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.local_hospital_rounded, color: Colors.white),
      ),
      if (!compact) ...[
        const SizedBox(width: 11),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shrinovva Homeophatic',
                style: TextStyle(
                  fontFamily: AppTypography.heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Patient care system',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 7),
          Text(subtitle, style: const TextStyle(fontSize: 13, height: 1.6)),
        ],
      );
      if (constraints.maxWidth < 600) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: heading),
          if (action != null) ...[const SizedBox(width: 16), action!],
        ],
      );
    },
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    this.caption,
  });
  final String label, value;
  final IconData icon;
  final Color tint;
  final String? caption;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const Spacer(),
              if (caption != null)
                Text(
                  caption!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: Text(
              value,
              key: ValueKey(value),
              style: const TextStyle(
                fontFamily: AppTypography.heading,
                fontSize: 28,
                letterSpacing: -1,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class PatientAvatar extends StatelessWidget {
  const PatientAvatar({super.key, required this.initials, this.radius = 22});
  final String initials;
  final double radius;
  @override
  Widget build(BuildContext context) {
    const palette = [
      Color(0xFFEAF0FD),
      Color(0xFFE6F3EF),
      Color(0xFFF7EDE5),
      Color(0xFFEEEAF8),
    ];
    const inks = [
      AppColors.primary,
      Color(0xFF337C68),
      Color(0xFF9D714D),
      Color(0xFF7B60AA),
    ];
    final variant =
        initials.codeUnits.fold(0, (a, b) => a + b) % palette.length;
    return CircleAvatar(
      radius: radius,
      backgroundColor: palette[variant],
      child: Text(
        initials,
        style: TextStyle(
          color: inks[variant],
          fontWeight: FontWeight.w800,
          fontSize: radius * .58,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final TicketStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TicketStatus.completed => AppColors.success,
      TicketStatus.inConsultation => AppColors.teal,
      TicketStatus.cancelled => AppColors.danger,
      TicketStatus.draft => AppColors.muted,
      _ => AppColors.primary,
    };
    return _Badge(label: status.label, color: color);
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});
  final Priority priority;
  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      Priority.normal => AppColors.teal,
      Priority.urgent => AppColors.warning,
      Priority.emergency => AppColors.danger,
    };
    return _Badge(label: priority.label, color: color);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.icon,
  });
  final String title;
  final Widget child;
  final Widget? trailing;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(36),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ClinicArt(records: true, height: 105),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}

String shortDate(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
