import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/patient_summary.dart';
import 'patient_profile_page.dart';

class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key, required this.ticket});
  final Ticket ticket;
  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final findings = TextEditingController();
  final exam = TextEditingController();
  final diagnosis = TextEditingController();
  final treatment = TextEditingController();
  final medicine = TextEditingController();
  final dosage = TextEditingController();
  final recommendations = TextEditingController();
  DateTime? followUp;
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final patient = state.patientFor(widget.ticket.patientId);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('${widget.ticket.queueNumber} • Consultation'),
        actions: [
          StatusBadge(status: widget.ticket.status),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PatientSummary(
                  patient: patient,
                  action: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientProfilePage(patient: patient),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 17),
                    label: const Text('Patient profile'),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (_, c) {
                    final visit = _VisitPanel(ticket: widget.ticket);
                    final contextPanel = _ContextPanel(patient: patient);
                    return c.maxWidth > 850
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: visit),
                              const SizedBox(width: 16),
                              Expanded(child: contextPanel),
                            ],
                          )
                        : Column(
                            children: [
                              visit,
                              const SizedBox(height: 16),
                              contextPanel,
                            ],
                          );
                  },
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Doctor entry',
                  icon: Icons.edit_note_rounded,
                  child: Column(
                    children: [
                      TextField(
                        controller: findings,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Consultation findings *',
                          hintText: 'Document relevant clinical findings',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: exam,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Physical examination',
                          hintText: 'Physical examination',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: diagnosis,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Diagnosis *',
                          hintText: 'Diagnosis *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: treatment,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Treatment plan *',
                          hintText: 'Treatment plan *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (_, c) => Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: c.maxWidth > 600
                                  ? (c.maxWidth - 10) * .65
                                  : c.maxWidth,
                              child: TextField(
                                controller: medicine,
                                decoration: const InputDecoration(
                                  labelText: 'Medicine',
                                  hintText: 'e.g. Paracetamol 500 mg',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: c.maxWidth > 600
                                  ? (c.maxWidth - 10) * .35
                                  : c.maxWidth,
                              child: TextField(
                                controller: dosage,
                                decoration: const InputDecoration(
                                  labelText: 'Frequency & duration',
                                  hintText: 'Frequency & duration',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: recommendations,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Recommendations',
                          hintText: 'Recommendations',
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (d != null) setState(() => followUp = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Follow-up date',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            followUp == null
                                ? 'No follow-up selected'
                                : shortDate(followUp!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Consultation draft saved locally.',
                              ),
                            ),
                          ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save draft'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => _complete(state, patient),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Complete consultation'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _complete(AppState state, Patient patient) {
    if (findings.text.trim().isEmpty ||
        diagnosis.text.trim().isEmpty ||
        treatment.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete findings, diagnosis, and treatment before finishing.',
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.verified_outlined,
          color: AppColors.success,
          size: 38,
        ),
        title: const Text('Complete this consultation?'),
        content: Text(
          'The consultation for ${patient.fullName} will become part of the patient history. Completed medical notes are read-only for clinic staff.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Review notes'),
          ),
          FilledButton(
            onPressed: () {
              state.completeTicket(
                widget.ticket,
                Consultation(
                  date: DateTime.now(),
                  doctor: widget.ticket.doctor,
                  complaint: widget.ticket.complaint,
                  diagnosis: diagnosis.text,
                  treatment: treatment.text,
                  prescription: medicine.text.isEmpty
                      ? 'No prescription'
                      : '${medicine.text} — ${dosage.text}',
                ),
              );
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${widget.ticket.queueNumber} completed and added to patient history.',
                  ),
                ),
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

class _VisitPanel extends StatelessWidget {
  const _VisitPanel({required this.ticket});
  final Ticket ticket;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Current visit',
    icon: Icons.assignment_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ticket.complaint,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(ticket.reason),
        const Divider(height: 28),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ticket.symptoms.map((s) => Chip(label: Text(s))).toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            Text('BP ${ticket.bloodPressure} mmHg'),
            Text('HR ${ticket.heartRate} bpm'),
            Text('${ticket.temperature}°C'),
            Text('SpO₂ ${ticket.oxygen}%'),
          ],
        ),
        if (ticket.notes.isNotEmpty) ...[
          const Divider(height: 28),
          Text('Staff note: ${ticket.notes}'),
        ],
      ],
    ),
  );
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Medical context',
    icon: Icons.medical_information_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HISTORY', style: _mini),
        Text(patient.medicalHistory),
        const SizedBox(height: 13),
        const Text('CONDITIONS', style: _mini),
        Text(
          patient.conditions.isEmpty
              ? 'None recorded'
              : patient.conditions.join(', '),
        ),
        const SizedBox(height: 13),
        const Text('MEDICATIONS', style: _mini),
        Text(
          patient.medications.isEmpty
              ? 'None recorded'
              : patient.medications.join('\n'),
        ),
        const SizedBox(height: 13),
        const Text('LATEST LABS', style: _mini),
        Text(patient.labs),
        const SizedBox(height: 13),
        Text(
          '${patient.consultations.length} previous consultation(s)',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

const _mini = TextStyle(
  fontSize: 10,
  letterSpacing: .8,
  fontWeight: FontWeight.w800,
  color: AppColors.muted,
);
