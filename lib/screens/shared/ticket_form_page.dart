import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../Database/doctor_database.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/intake_form_section.dart';
import '../../widgets/symptom_selector.dart';

class TicketFormPage extends StatefulWidget {
  const TicketFormPage({
    super.key,
    this.initialPatient,
    this.initialSymptoms = const [],
    this.walkthroughBackKey,
  });
  final Patient? initialPatient;
  final Key? walkthroughBackKey;
  final List<String> initialSymptoms;

  @override
  State<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends State<TicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientKey = GlobalKey<FormFieldState<Patient>>();
  final _complaintKey = GlobalKey<FormFieldState<String>>();
  final _reasonKey = GlobalKey<FormFieldState<String>>();
  final _doctorKey = GlobalKey<FormFieldState<String>>();
  final complaint = TextEditingController();
  final reason = TextEditingController();
  final notes = TextEditingController();
  final bp = TextEditingController();
  final heart = TextEditingController();
  final temp = TextEditingController();
  final oxygen = TextEditingController();
  bool _saving = false;
  Ticket? _pendingTicket;
  Patient? patient;
  String doctor = '';
  String? doctorUid;
  List<DoctorOption> _doctors = [];
  bool _loadingDoctors = true;
  String? _doctorError;
  bool _requestedDoctors = false;
  Priority priority = Priority.normal;
  final selected = <String>{};

  @override
  void initState() {
    super.initState();
    patient = widget.initialPatient;
    selected.addAll(widget.initialSymptoms);
    complaint.addListener(_refresh);
    reason.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedDoctors) {
      _requestedDoctors = true;
      _loadDoctors();
    }
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loadingDoctors = true;
      _doctorError = null;
    });
    try {
      final loaded = await AppStateScope.of(context).doctorDatabase
          .loadDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = loaded;
        _loadingDoctors = false;
        if (loaded.isEmpty) {
          _doctorError = 'No doctors with a username are available.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingDoctors = false;
          _doctorError =
              'Unable to load doctors. Check your connection and retry.';
        });
      }
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final controller in [
      complaint,
      reason,
      notes,
      bp,
      heart,
      temp,
      oxygen,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _completed =>
      (doctorUid == null ? 0 : 1) +
      (patient == null ? 0 : 1) +
      (complaint.text.trim().isEmpty ? 0 : 1) +
      (reason.text.trim().isEmpty ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: widget.walkthroughBackKey == null
            ? null
            : BackButton(key: widget.walkthroughBackKey),
        backgroundColor: Colors.white,
        title: const Text('Consultation ticket'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      bottomNavigationBar: _actions(state),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: AbsorbPointer(
                absorbing: _saving || _pendingTicket != null,
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageHeading(
                        title: 'New consultation',
                        subtitle: 'Start with the patient, then add the details of their visit.',
                      ),
                      const SizedBox(height: 20),
                      _progress(),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final main = Column(
                            children: [
                              _patientSection(state),
                              const SizedBox(height: 20),
                              _visitSection(),
                              const SizedBox(height: 20),
                              _symptomsSection(),
                            ],
                          );
                          final side = Column(
                            children: [
                              _vitalsSection(),
                              const SizedBox(height: 20),
                              _assignmentSection(),
                            ],
                          );
                          if (constraints.maxWidth < 960) {
                            return Column(
                              children: [
                                main,
                                const SizedBox(height: 20),
                                side,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: main),
                              const SizedBox(width: 24),
                              SizedBox(width: 350, child: side),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progress() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF0FD),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _completed == 4
                  ? Icons.check_circle_outline
                  : Icons.edit_note_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _completed == 4
                    ? 'Ready to review'
                    : 'A few details to get started',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$_completed / 4',
              style: const TextStyle(color: AppColors.primaryDark),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: _completed / 4,
          minHeight: 5,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.white,
          semanticsLabel: 'Required details completed',
        ),
        const SizedBox(height: 10),
        const Text(
          'Patient, main complaint, reason for consultation and assigned doctor are required.',
          style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
        ),
      ],
    ),
  );

  Widget _patientSection(AppState state) => IntakeFormSection(
    number: '01',
    title: 'Patient',
    subtitle: 'Choose who this consultation is for.',
    child: FormField<Patient>(
      key: _patientKey,
      initialValue: patient,
      validator: (value) =>
          value == null ? 'Choose a patient to continue.' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (patient == null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: () => _choosePatient(state),
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('Search for a patient'),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PatientAvatar(initials: patient!.initials),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient!.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${patient!.id} • ${patient!.age} years • ${patient!.gender}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Change patient',
                        onPressed: () => _choosePatient(state),
                        icon: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (patient!.allergies.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      'Recorded allergies: ${patient!.allergies.join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                field.errorText!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _choosePatient(AppState state) async {
    final result = await showDialog<Patient>(
      context: context,
      builder: (_) => _PatientPicker(patients: state.patients),
    );
    if (!mounted || result == null) return;
    setState(() => patient = result);
    _patientKey.currentState!.didChange(result);
  }

  Widget _visitSection() => IntakeFormSection(
    number: '02',
    title: 'Visit details',
    subtitle: 'Describe the concern in the patient’s own words.',
    child: Column(
      children: [
        TextFormField(
          key: _complaintKey,
          controller: complaint,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Main complaint *',
            hintText: 'e.g. Headache and dizziness',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter the main complaint.'
              : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          key: _reasonKey,
          controller: reason,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Reason for consultation *',
            hintText:
                'What brought the patient in today? Include when it started.',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter the reason for consultation.'
              : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: notes,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Staff notes (optional)',
            hintText: 'Add any other details for the doctor.',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
      ],
    ),
  );

  Widget _symptomsSection() => IntakeFormSection(
    number: '03',
    title: 'Symptoms',
    subtitle: 'Optional · Select all reported symptoms.',
    child: SymptomSelector(
      selected: selected,
      onChanged: (value) => setState(() {
        selected
          ..clear()
          ..addAll(value);
      }),
    ),
  );
  Widget _vitalsSection() => IntakeFormSection(
    icon: Icons.monitor_heart_outlined,
    title: 'Vital signs',
    subtitle: 'Optional · Enter measured values only.',
    child: LayoutBuilder(
      builder: (_, constraints) {
        final columns = constraints.maxWidth >= 280 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 20,
          children: [
            _vitalField(width, bp, 'Blood pressure', '120/80', 'mmHg'),
            _vitalField(width, heart, 'Heart rate', '76', 'bpm', numeric: true),
            _vitalField(
              width,
              temp,
              'Temperature',
              '36.7',
              '°C',
              numeric: true,
            ),
            _vitalField(width, oxygen, 'Oxygen', '98', '%', numeric: true),
          ],
        );
      },
    ),
  );

  Widget _vitalField(
    double width,
    TextEditingController controller,
    String label,
    String hint,
    String unit, {
    bool numeric = false,
  }) => SizedBox(
    width: width,
    child: TextFormField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit,
        suffixStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
    ),
  );

  Widget _assignmentSection() => IntakeFormSection(
    icon: Icons.medical_services_outlined,
    title: 'Care assignment',
    subtitle: 'Choose the doctor and visit priority.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: _doctorKey,
          isExpanded: true,
          initialValue: doctorUid,
          decoration: const InputDecoration(
            labelText: 'Assigned doctor *',
            hintText: 'Select a doctor',
            helperText: 'The selected doctor receives the ticket notification.',
            helperMaxLines: 3,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          items: _doctors
              .map(
                (value) => DropdownMenuItem(
                  value: value.uid,
                  child: Text(value.username, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          validator: (value) =>
              value == null ? 'Choose the doctor in charge.' : null,
          onChanged: _loadingDoctors
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      doctorUid = value;
                      doctor = _doctors
                          .firstWhere((d) => d.uid == value)
                          .username;
                    });
                  }
                },
        ),
        const SizedBox(height: 20),
        if (_loadingDoctors) const LinearProgressIndicator(),
        if (_doctorError != null) ...[
          Text(_doctorError!, style: const TextStyle(color: AppColors.danger)),
          TextButton(
            onPressed: _loadDoctors,
            child: const Text('Retry loading doctors'),
          ),
        ],
        const Text(
          'Visit priority',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: Priority.values.map((value) {
            final color = switch (value) {
              Priority.normal => AppColors.primary,
              Priority.urgent => AppColors.warning,
              Priority.emergency => AppColors.danger,
            };
            return ChoiceChip(
              label: Text(value.label),
              labelStyle: TextStyle(
                color: priority != value
                    ? AppColors.ink
                    : value == Priority.urgent
                    ? const Color(0xFF875000)
                    : color,
                fontWeight: FontWeight.w600,
              ),
              selected: priority == value,
              selectedColor: color.withValues(alpha: .12),
              checkmarkColor: color,
              onSelected: (_) => setState(() => priority = value),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        const Text(
          'Review the patient and visit details before sending to the doctor.',
          style: TextStyle(fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );

  Widget _actions(AppState state) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final submit = FilledButton.icon(
                  onPressed: _saving ? null : () => _submit(state),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    _saving
                        ? 'Saving ticket...'
                        : _pendingTicket != null
                        ? 'Retry save'
                        : 'Review & send',
                  ),
                );
                if (constraints.maxWidth < 900 ||
                    MediaQuery.textScalerOf(context).scale(14) > 17) {
                  return OverflowBar(
                    spacing: 10,
                    overflowSpacing: 8,
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    children: [submit],
                  );
                }
                return Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    Text(
                      _completed == 4
                          ? 'Required details complete'
                          : '$_completed of 4 required details',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 20),
                    submit,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _submit(AppState state) async {
    if (_saving) return;
    if (_pendingTicket != null) {
      await _saveTicket(state, _pendingTicket!);
      return;
    }
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      for (final key in <GlobalKey<FormFieldState>>[
        _patientKey,
        _complaintKey,
        _reasonKey,
        _doctorKey,
      ]) {
        if (key.currentState?.hasError ?? false) {
          await Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 250),
            alignment: .15,
          );
          break;
        }
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: 540),
        icon: const Icon(
          Icons.fact_check_outlined,
          color: AppColors.primary,
          size: 32,
        ),
        title: const Text('Review consultation'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _reviewDetail(
                  'Patient',
                  '${patient!.fullName} · ${patient!.id}',
                ),
                _reviewDetail('Assigned doctor', doctor),
                _reviewDetail('Priority', priority.label),
                const Divider(height: 24),
                _reviewDetail('Main complaint', complaint.text.trim()),
                _reviewDetail('Reason for consultation', reason.text.trim()),
                _reviewDetail(
                  'Symptoms',
                  selected.isEmpty ? 'None selected' : selected.join(', '),
                ),
                _reviewDetail('Blood pressure', _measurement(bp, 'mmHg')),
                _reviewDetail('Heart rate', _measurement(heart, 'bpm')),
                _reviewDetail('Temperature', _measurement(temp, '°C')),
                _reviewDetail('Oxygen', _measurement(oxygen, '%')),
                if (notes.text.trim().isNotEmpty)
                  _reviewDetail('Staff notes', notes.text.trim()),
                const SizedBox(height: 8),
                const Text(
                  'This ticket will be available in the doctor workspace.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send ticket'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      final id = state.ticketDatabase.newTicketId();
      final ticket = Ticket(
        id: id,
        queueNumber: 'No.1',
        patientId: patient!.id,
        complaint: complaint.text.trim(),
        reason: reason.text.trim(),
        symptoms: selected.toList(),
        bloodPressure: bp.text.trim(),
        heartRate: heart.text.trim(),
        temperature: temp.text.trim(),
        oxygen: oxygen.text.trim(),
        doctor: doctor,
        doctorUid: doctorUid!,
        priority: priority,
        notes: notes.text.trim(),
        createdAt: DateTime.now(),
        status: TicketStatus.sent,
      );
      _pendingTicket = ticket;
      await _saveTicket(state, ticket);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not prepare ticket. Please retry.'),
        ),
      );
    }
  }

  Future<void> _saveTicket(AppState state, Ticket ticket) async {
    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      await state.addTicket(ticket);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${ticket.queueNumber} sent to ${ticket.doctor} successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the ticket. Check your connection and retry. Your original submission will be retried.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _measurement(TextEditingController controller, String unit) =>
      controller.text.trim().isEmpty
      ? 'Not recorded'
      : '${controller.text.trim()} $unit';

  Widget _reviewDetail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _PatientPicker extends StatefulWidget {
  const _PatientPicker({required this.patients});
  final List<Patient> patients;

  @override
  State<_PatientPicker> createState() => _PatientPickerState();
}

class _PatientPickerState extends State<_PatientPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final matches = widget.patients
        .where((patient) => patient.matchesSearch(query))
        .toList();
    final compact =
        MediaQuery.sizeOf(context).height -
            MediaQuery.viewInsetsOf(context).bottom <
        280;
    return Scaffold(
      appBar: compact
          ? null
          : AppBar(
              title: const Text('Choose a patient'),
              leading: IconButton(
                tooltip: 'Close patient search',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: compact ? 4 : 16,
              ),
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    onChanged: (value) => setState(() => query = value),
                    decoration: InputDecoration(
                      hintText: 'Search last name, first name or patient ID',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: compact
                          ? IconButton(
                              tooltip: 'Close patient search',
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            )
                          : null,
                    ),
                  ),
                  if (!compact) const SizedBox(height: 12),
                  Expanded(
                    child: matches.isEmpty
                        ? const Center(
                            child: Text(
                              'No patients found. Try a different name or ID.',
                            ),
                          )
                        : ListView.separated(
                            itemCount: matches.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final patient = matches[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                leading: PatientAvatar(
                                  initials: patient.initials,
                                  radius: 20,
                                ),
                                title: Text(patient.fullName),
                                subtitle: Text(
                                  '${patient.id} · ${patient.age} years · ${patient.gender}',
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: () => Navigator.pop(context, patient),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
