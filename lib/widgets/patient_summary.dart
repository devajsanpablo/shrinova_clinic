import 'package:flutter/material.dart';

import '../models/models.dart';
import 'common.dart';

class PatientSummary extends StatelessWidget {
  const PatientSummary({
    super.key,
    required this.patient,
    required this.action,
  });
  final Patient patient;
  final Widget action;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final summary = Row(
            children: [
              PatientAvatar(initials: patient.initials, radius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${patient.id} · ${patient.age} years · ${patient.gender}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (constraints.maxWidth >= 650)
                Row(
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 18),
                    action,
                  ],
                )
              else ...[
                summary,
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, child: action),
              ],
              if (patient.allergies.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Color(0xFF9E522B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Allergies: ${patient.allergies.join(', ')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E522B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
