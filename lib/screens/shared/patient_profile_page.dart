import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_state.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/patient_summary.dart';
import 'ticket_form_page.dart';

class PatientProfilePage extends StatelessWidget {
  const PatientProfilePage({
    super.key,
    required this.patient,
    this.historyStream,
  });
  final Patient patient;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? historyStream;
  void _openImage(BuildContext context, int index) {
    final file = patient.labAttachments[index];
    final image = file.bytes != null
        ? Future<Uint8List>.value(file.bytes)
        : AppStateScope.of(context).database.loadLabImage(patient.id, index);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 900,
          height: 650,
          child: Column(
            children: [
              ListTile(
                title: Text(file.name),
                trailing: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
              Expanded(
                child: FutureBuilder<Uint8List>(
                  future: image,
                  builder: (_, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Could not load this image. Close and try again.',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return InteractiveViewer(
                      maxScale: 6,
                      child: Image.memory(
                        snapshot.data!,
                        errorBuilder: (_, error, stack) =>
                            const Text('This image cannot be displayed.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                          const Text('VACCINATION', style: _label),
                          const SizedBox(height: 6),
                          Text(
                            patient.vaccinationStatus == 'Yes'
                                ? patient.vaccines.join(', ')
                                : patient.vaccinationStatus == 'No'
                                ? 'No vaccines reported'
                                : 'Not recorded',
                          ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient.labs),
                          for (
                            var i = 0;
                            i < patient.labAttachments.length;
                            i++
                          )
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.image_outlined),
                              title: Text(patient.labAttachments[i].name),
                              subtitle: const Text(
                                'Tap to view laboratory result',
                              ),
                              onTap: () => _openImage(context, i),
                            ),
                        ],
                      ),
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
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      historyStream ??
                      FirebaseFirestore.instance
                          .collection('patients')
                          .doc(patient.id)
                          .collection('checkupHistory')
                          .orderBy('recordedAt', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    final visits =
                        snapshot.data?.docs.map((doc) {
                          final map = Map<String, dynamic>.from(
                            doc.data()['consultation'] as Map,
                          );
                          return Consultation(
                            date: DateTime.parse(map['date'] as String),
                            doctor: map['doctor'] as String,
                            complaint: map['complaint'] as String,
                            diagnosis: map['diagnosis'] as String,
                            treatment: map['treatment'] as String,
                            prescription: map['prescription'] as String,
                          );
                        }).toList() ??
                        patient.consultations;
                    if (snapshot.hasError) {
                      return const Text('Unable to load consultation history.');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        visits.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (visits.isEmpty) {
                      return const EmptyState(
                        title: 'No previous visits',
                        message: 'Completed consultations will appear here.',
                      );
                    }
                    return Column(
                      children: visits
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
                    );
                  },
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
