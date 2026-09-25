import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/patient_summary.dart';
import '../shared/patient_profile_page.dart';

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
  bool _saving = false;
  bool get _closed =>
      widget.ticket.status == TicketStatus.completed ||
      widget.ticket.status == TicketStatus.cancelled;

  @override
  void dispose() {
    for (final controller in [
      findings,
      exam,
      diagnosis,
      treatment,
      medicine,
      dosage,
      recommendations,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final patient = state.patientFor(widget.ticket.patientId);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Consultation'),
        actions: [
          StatusBadge(status: widget.ticket.status),
          const SizedBox(width: 16),
        ],
      ),
      bottomNavigationBar: _closed
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Review the patient and visit details before completing.',
                        style: TextStyle(fontSize: 12),
                      ),
                      FilledButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _complete(state, patient),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          _saving
                              ? 'Saving consultation...'
                              : 'Complete consultation',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
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
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final main = Column(
                        children: [
                          _VisitPanel(ticket: widget.ticket),
                          const SizedBox(height: 20),
                          _VitalsPanel(ticket: widget.ticket),
                          const SizedBox(height: 20),
                          if (_closed)
                            _CompletedPanel(ticket: widget.ticket)
                          else
                            _doctorEntry(),
                        ],
                      );
                      final sidebar = Column(
                        children: [
                          _PatientDetails(patient: patient),
                          const SizedBox(height: 20),
                          _ContextPanel(patient: patient),
                          const SizedBox(height: 20),
                          _HistoryPanel(patient: patient),
                        ],
                      );
                      if (constraints.maxWidth < 1000) {
                        return Column(
                          children: [
                            _VisitPanel(ticket: widget.ticket),
                            const SizedBox(height: 20),
                            _VitalsPanel(ticket: widget.ticket),
                            const SizedBox(height: 20),
                            sidebar,
                            const SizedBox(height: 20),
                            if (_closed)
                              _CompletedPanel(ticket: widget.ticket)
                            else
                              _doctorEntry(),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: main),
                          const SizedBox(width: 20),
                          Expanded(flex: 4, child: sidebar),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _doctorEntry() => SectionCard(
    title: 'Clinical assessment',
    icon: Icons.edit_note_rounded,
    child: Column(
      children: [
        TextField(
          controller: findings,
          maxLines: 3,
          decoration: const InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: 'Consultation findings *',
            hintText: 'Document relevant clinical findings',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: exam,
          maxLines: 3,
          decoration: const InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: 'Physical examination',
            hintText: 'Physical examination',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: diagnosis,
          maxLines: 2,
          decoration: const InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: 'Diagnosis *',
            hintText: 'Diagnosis *',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: treatment,
          maxLines: 3,
          decoration: const InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
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
                width: c.maxWidth > 600 ? (c.maxWidth - 10) * .65 : c.maxWidth,
                child: TextField(
                  controller: medicine,
                  decoration: const InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: 'Medicine',
                    hintText: 'e.g. Paracetamol 500 mg',
                  ),
                ),
              ),
              SizedBox(
                width: c.maxWidth > 600 ? (c.maxWidth - 10) * .35 : c.maxWidth,
                child: TextField(
                  controller: dosage,
                  decoration: const InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
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
            floatingLabelBehavior: FloatingLabelBehavior.always,
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
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (mounted && d != null) setState(() => followUp = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelText: 'Follow-up date',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              followUp == null ? 'No follow-up selected' : shortDate(followUp!),
            ),
          ),
        ),
      ],
    ),
  );

  void _complete(AppState state, Patient patient) {
    if (_saving || _closed) return;
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
            onPressed: () async {
              if (_saving) return;
              setState(() => _saving = true);
              Navigator.pop(dialogContext);
              try {
                await state.completeTicket(
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
                if (!mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '${widget.ticket.queueNumber} completed and added to patient history.',
                    ),
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not save consultation. Please retry.'),
                  ),
                );
              } finally {
                if (mounted) setState(() => _saving = false);
              }
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
    title: 'Visit details',
    icon: Icons.assignment_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              labelStyle: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
              avatar: Icon(
                Icons.flag_outlined,
                size: 17,
                color: ticket.priority == Priority.normal
                    ? AppColors.primary
                    : AppColors.danger,
              ),
              label: Text('${ticket.priority.label} priority'),
            ),
            Text(
              'Assigned to ${ticket.doctor}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MAIN COMPLAINT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _recorded(ticket.complaint),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Reason for consultation',
                style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 4),
              Text(
                _recorded(ticket.reason),
                style: const TextStyle(color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _Label('Reported symptoms'),
        const SizedBox(height: 8),
        if (ticket.symptoms.isEmpty)
          const Text('No symptoms recorded')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ticket.symptoms
                .map(
                  (s) => Chip(
                    label: Text(s),
                    labelStyle: const TextStyle(color: AppColors.ink),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 20),
        _Detail('Staff notes', ticket.notes),
        const Divider(height: 28),
        _DetailGrid(
          items: [
            ('Ticket ID', ticket.id),
            ('Queue reference', ticket.queueNumber),
            ('Created', _dateTime(context, ticket.createdAt)),
            ('Status', ticket.status.label),
          ],
        ),
      ],
    ),
  );
}

class _VitalsPanel extends StatelessWidget {
  const _VitalsPanel({required this.ticket});
  final Ticket ticket;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Recorded vital signs',
    icon: Icons.monitor_heart_outlined,
    child: LayoutBuilder(
      builder: (_, constraints) {
        final columns = constraints.maxWidth >= 560
            ? 4
            : constraints.maxWidth >= 260
            ? 2
            : 1;
        final readings = [
          (
            'Blood pressure',
            ticket.bloodPressure,
            'mmHg',
            Icons.favorite_border,
          ),
          ('Heart rate', ticket.heartRate, 'bpm', Icons.monitor_heart_outlined),
          ('Temperature', ticket.temperature, '°C', Icons.thermostat_outlined),
          ('Oxygen saturation', ticket.oxygen, '%', Icons.air),
        ];
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: readings
              .map(
                (v) => SizedBox(
                  width: (constraints.maxWidth - (columns - 1) * 10) / columns,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(v.$4, color: AppColors.teal, size: 21),
                        const SizedBox(height: 12),
                        Text(v.$1, style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 6),
                        Text(
                          v.$2.trim().isEmpty
                              ? 'Not recorded'
                              : '${v.$2} ${v.$3}',
                          style: TextStyle(
                            fontSize: v.$2.trim().isEmpty ? 13 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class _PatientDetails extends StatelessWidget {
  const _PatientDetails({required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Patient details',
    icon: Icons.person_outline,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailGrid(
          items: [
            ('Patient ID', patient.id),
            ('Date of birth', shortDate(patient.dateOfBirth)),
            ('Age', '${patient.age} years'),
            ('Gender', patient.gender),
          ],
        ),
        const SizedBox(height: 16),
        _Detail('Phone number', patient.phone),
        const SizedBox(height: 16),
        _Detail('Address', patient.address),
        const Divider(height: 28),
        _Detail('Emergency contact', patient.emergencyContactName),
        const SizedBox(height: 16),
        _Detail('Emergency phone', patient.emergencyContactPhone),
        const SizedBox(height: 16),
        _Detail('Registered', _dateTime(context, patient.registeredAt)),
      ],
    ),
  );
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Medical background',
    icon: Icons.medical_information_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Detail(
          'Allergies',
          patient.allergies.isEmpty
              ? 'No allergies recorded'
              : patient.allergies.join(', '),
        ),
        const Divider(height: 28),
        _Detail('Medical history', patient.medicalHistory),
        const SizedBox(height: 18),
        _Detail('Existing conditions', patient.conditions.join(', ')),
        const SizedBox(height: 18),
        _Detail('Current medications', patient.medications.join('\n')),
        const SizedBox(height: 18),
        _Detail('Laboratory findings', patient.labs),
      ],
    ),
  );
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Consultation history',
    icon: Icons.history_rounded,
    child: patient.consultations.isEmpty
        ? const Text('No consultations recorded')
        : Column(
            children:
                (patient.consultations.toList()
                      ..sort((a, b) => b.date.compareTo(a.date)))
                    .map(
                      (c) => ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 16),
                        title: Text(
                          c.diagnosis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${shortDate(c.date)} · ${c.doctor}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Detail('Complaint', c.complaint),
                                const SizedBox(height: 12),
                                _Detail('Treatment', c.treatment),
                                const SizedBox(height: 12),
                                _Detail('Prescription', c.prescription),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
          ),
  );
}

class _CompletedPanel extends StatelessWidget {
  const _CompletedPanel({required this.ticket});
  final Ticket ticket;
  @override
  Widget build(BuildContext context) {
    final c = ticket.consultation;
    return SectionCard(
      title: 'Consultation record',
      icon: Icons.task_alt,
      child: c == null
          ? const Text('No completed consultation notes recorded.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Detail('Completed', _dateTime(context, c.date)),
                const SizedBox(height: 16),
                _Detail('Doctor', c.doctor),
                const SizedBox(height: 16),
                _Detail('Diagnosis', c.diagnosis),
                const SizedBox(height: 16),
                _Detail('Treatment plan', c.treatment),
                const SizedBox(height: 16),
                _Detail('Prescription', c.prescription),
              ],
            ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.items});
  final List<(String, String)> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final two = constraints.maxWidth >= 300;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: items
            .map(
              (item) => SizedBox(
                width: two
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth,
                child: _Detail(item.$1, item.$2),
              ),
            )
            .toList(),
      );
    },
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      color: AppColors.muted,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label(label),
      const SizedBox(height: 5),
      Text(
        _recorded(value),
        style: const TextStyle(color: AppColors.ink, height: 1.5),
      ),
    ],
  );
}

String _recorded(String value) => value.trim().isEmpty ? 'Not recorded' : value;
String _dateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final strings = MaterialLocalizations.of(context);
  return '${shortDate(local)} · ${strings.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
