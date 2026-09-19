import 'package:flutter/material.dart';

import '../core/theme.dart';

class IntakeFormSection extends StatelessWidget {
  const IntakeFormSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.number,
    this.icon,
  });
  final String title, subtitle;
  final String? number;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FD),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: number != null
                    ? Text(
                        number!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.5)),
          const SizedBox(height: 22),
          child,
        ],
      ),
    ),
  );
}
