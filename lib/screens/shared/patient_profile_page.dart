import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/patient_summary.dart';
import 'ticket_form_page.dart';

class PatientProfilePage extends StatelessWidget {
  const PatientProfilePage({super.key, required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text('Patient profile'),
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 18 : 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PatientSummary(
                patient: patient,
                action: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketFormPage(initialPatient: patient),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create ticket'),
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, c) {
                  final items = [
                    SectionCard(
                      title: 'Personal information',
                      icon: Icons.person_outline,
                      child: _Info(
                        rows: {
                          'Phone': patient.phone,
                          'Address': patient.address,
                          if (patient.emergencyContactName.isNotEmpty)
                            'Emergency contact': patient.emergencyContactName,
                          if (patient.emergencyContactPhone.isNotEmpty)
                            'Emergency phone': patient.emergencyContactPhone,
                          'Date of birth': shortDate(patient.dateOfBirth),
                          'Registered': shortDate(patient.registeredAt),
                        },
                      ),
                    ),
                    SectionCard(
                      title: 'Medical context',
                      icon: Icons.medical_information_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MEDICAL HISTORY', style: _label),
                          const SizedBox(height: 5),
                          Text(patient.medicalHistory),
                          const SizedBox(height: 15),
                          const Text('EXISTING CONDITIONS', style: _label),
                          const SizedBox(height: 6),
                          Text(
                            patient.conditions.isEmpty
                                ? 'None recorded'
                                : patient.conditions.join(', '),
                          ),
                          const SizedBox(height: 15),
                          const Text('CURRENT MEDICATIONS', style: _label),
                          const SizedBox(height: 6),
                          Text(
                            patient.medications.isEmpty
                                ? 'None recorded'
                                : patient.medications.join('\n'),
                          ),
                        ],
                      ),
                    ),
                    SectionCard(
                      title: 'Laboratory findings',
                      icon: Icons.science_outlined,
                      child: Text(patient.labs),
                    ),
                  ];
                  return c.maxWidth > 780
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  items[0],
                                  const SizedBox(height: 16),
                                  items[2],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: items[1]),
                          ],
                        )
                      : Column(
                          children: items
                              .expand((e) => [e, const SizedBox(height: 14)])
                              .toList(),
                        );
                },
              ),
              const SizedBox(height: 4),
              SectionCard(
                title: 'Consultation history',
                icon: Icons.history_rounded,
                child: patient.consultations.isEmpty
                    ? const EmptyState(
                        title: 'No previous visits',
                        message: 'Completed consultations will appear here.',
                      )
                    : Column(
                        children: patient.consultations
                            .map(
                              (v) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.canvas,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(top: 5),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${shortDate(v.date)} • ${v.doctor}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${v.complaint}\nDiagnosis: ${v.diagnosis}\nTreatment: ${v.treatment}\nPrescription: ${v.prescription}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

const _label = TextStyle(
  fontSize: 10,
  letterSpacing: .8,
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);

class _Info extends StatelessWidget {
  const _Info({required this.rows});
  final Map<String, String> rows;
  @override
  Widget build(BuildContext context) => Column(
    children: rows.entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    e.key,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}
