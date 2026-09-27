import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:uri_content/uri_content.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../model/patient.dart';
import '../../widgets/common.dart';
import '../../widgets/intake_form_section.dart';
import '../../widgets/symptom_selector.dart';
import 'ticket_form_page.dart';

class RegisterPatientPage extends StatefulWidget {
  const RegisterPatientPage({super.key, this.walkthroughBackKey});
  final Key? walkthroughBackKey;

  @override
  State<RegisterPatientPage> createState() => _RegisterPatientPageState();
}

class _RegisterPatientPageState extends State<RegisterPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstKey = GlobalKey<FormFieldState<String>>();
  final _lastKey = GlobalKey<FormFieldState<String>>();
  final _birthKey = GlobalKey<FormFieldState<String>>();
  final _phoneKey = GlobalKey<FormFieldState<String>>();
  final _addressKey = GlobalKey<FormFieldState<String>>();
  final _emergencyPhoneKey = GlobalKey<FormFieldState<String>>();
  final _vaccinesKey = GlobalKey<FormFieldState<String>>();
  final first = TextEditingController();
  final last = TextEditingController();
  final birth = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final history = TextEditingController();
  final allergies = TextEditingController();
  final conditions = TextEditingController();
  final medications = TextEditingController();
  final emergencyName = TextEditingController();
  final emergencyPhone = TextEditingController();
  final vaccines = TextEditingController();
  final labNotes = TextEditingController();
  String vaccinationStatus = 'Unknown';
  final List<LabAttachment> _labAttachments = [];
  bool _pickingImage = false;
  DateTime? dateOfBirth;
  String gender = 'Prefer not to say';
  bool _createTicket = false;
  bool _saving = false;
  String? _patientId;
  DateTime? _registeredAt;
  Set<String> _symptoms = {};

  List<TextEditingController> get _controllers => [
    first,
    last,
    birth,
    phone,
    address,
    history,
    allergies,
    conditions,
    medications,
    emergencyName,
    emergencyPhone,
    vaccines,
    labNotes,
  ];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_refresh);
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _recoverImage();
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _completed => [
    first.text.trim().isNotEmpty,
    last.text.trim().isNotEmpty,
    dateOfBirth != null,
    _phoneError(phone.text) == null,
    address.text.trim().isNotEmpty,
  ].where((complete) => complete).length;

  String get _fullName => [
    first.text.trim(),
    last.text.trim(),
  ].where((name) => name.isNotEmpty).join(' ');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: widget.walkthroughBackKey == null
          ? null
          : BackButton(key: widget.walkthroughBackKey),
      backgroundColor: Colors.white,
      title: const Text('Patient registration'),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    ),
    bottomNavigationBar: _actions(),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeading(
                    title: 'New patient',
                    subtitle: 'Start with personal details, then add contact and health information.',
                  ),
                  const SizedBox(height: 20),
                  _progress(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final main = Column(
                        children: [
                          _personalSection(),
                          const SizedBox(height: 20),
                          _contactSection(),
                          const SizedBox(height: 20),
                          _healthSection(),
                          const SizedBox(height: 20),
                          _laboratorySection(),
                          const SizedBox(height: 20),
                          _consultationSection(),
                        ],
                      );
                      final side = Column(
                        children: [
                          _summarySection(),
                          const SizedBox(height: 20),
                          _emergencySection(),
                        ],
                      );
                      if (constraints.maxWidth < 960) {
                        return Column(
                          children: [main, const SizedBox(height: 20), side],
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
  );

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
              _completed == 5
                  ? Icons.check_circle_outline
                  : Icons.person_add_alt_1_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _completed == 5
                    ? 'Ready to review'
                    : 'A few details to get started',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$_completed / 5',
              style: const TextStyle(color: AppColors.primaryDark),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: _completed / 5,
          minHeight: 5,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.white,
          semanticsLabel: 'Required details completed',
        ),
        const SizedBox(height: 10),
        const Text(
          'First name, last name, birth date, phone and address are required.',
          style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
        ),
      ],
    ),
  );

  Widget _personalSection() => IntakeFormSection(
    number: '01',
    title: 'Personal information',
    subtitle: 'Use the patient’s full name and confirmed date of birth.',
    child: Column(
      children: [
        _paired(
          _textField(
            key: _firstKey,
            controller: first,
            label: 'First name *',
            hint: 'e.g. Maria',
            capitalization: TextCapitalization.words,
            validator: (value) => _required(value, 'Enter the first name.'),
            autofillHints: const [AutofillHints.givenName],
          ),
          _textField(
            key: _lastKey,
            controller: last,
            label: 'Last name *',
            hint: 'e.g. Santos',
            capitalization: TextCapitalization.words,
            validator: (value) => _required(value, 'Enter the last name.'),
            autofillHints: const [AutofillHints.familyName],
          ),
        ),
        const SizedBox(height: 20),
        _paired(
          TextFormField(
            key: _birthKey,
            controller: birth,
            readOnly: true,
            onTap: _pickDate,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Date of birth *',
              hintText: 'Choose a date',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
            ),
            validator: (_) =>
                dateOfBirth == null ? 'Choose the date of birth.' : null,
          ),
          DropdownButtonFormField<String>(
            initialValue: gender,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Gender',
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            items: ['Female', 'Male', 'Other', 'Prefer not to say']
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => gender = value);
            },
          ),
        ),
      ],
    ),
  );

  Widget _contactSection() => IntakeFormSection(
    number: '02',
    title: 'Contact details',
    subtitle: 'Add the best way for the clinic to reach the patient.',
    child: Column(
      children: [
        _textField(
          key: _phoneKey,
          controller: phone,
          label: 'Phone number *',
          hint: 'e.g. 0917 123 4567',
          keyboardType: TextInputType.phone,
          validator: _phoneError,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        const SizedBox(height: 20),
        _textField(
          key: _addressKey,
          controller: address,
          label: 'Complete address *',
          hint: 'House or unit, street, barangay, city and province',
          lines: 2,
          capitalization: TextCapitalization.words,
          validator: (value) => _required(value, 'Enter the complete address.'),
          autofillHints: const [AutofillHints.fullStreetAddress],
        ),
      ],
    ),
  );

  Widget _healthSection() => IntakeFormSection(
    number: '03',
    title: 'Health information',
    subtitle: 'Optional · Record what the patient reports. Leave unknown details blank.',
    child: Column(
      children: [
        _textField(
          controller: history,
          label: 'Medical history',
          hint: 'Previous illnesses, surgeries or other relevant history',
          lines: 3,
        ),
        const SizedBox(height: 20),
        _textField(
          controller: allergies,
          label: 'Allergies',
          hint: 'e.g. Penicillin, peanuts',
          helper: 'Separate multiple allergies with commas.',
        ),
        const SizedBox(height: 20),
        _textField(
          controller: conditions,
          label: 'Existing conditions',
          hint: 'List any known conditions',
          helper: 'Separate multiple conditions with commas.',
        ),
        const SizedBox(height: 20),
        _textField(
          controller: medications,
          label: 'Current medications',
          hint: 'Include names and doses, if known',
          lines: 2,
          helper: 'Separate multiple medications with commas.',
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: vaccinationStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Vaccination history',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            helperText: 'Record past vaccinations reported by the patient or shown in their records. Unknown means the history has not been confirmed.',
            helperMaxLines: 4,
          ),
          items: ['Unknown', 'Yes', 'No']
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(switch (value) {
                    'Yes' => 'Yes — vaccines received',
                    'No' => 'No — none received',
                    _ => 'Unknown — not confirmed',
                  }, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => vaccinationStatus = value!),
        ),
        if (vaccinationStatus == 'Yes') ...[
          const SizedBox(height: 20),
          _textField(
            controller: vaccines,
            key: _vaccinesKey,
            label: 'Vaccine types *',
            hint: 'e.g. COVID-19, influenza, tetanus',
            helper: 'List known vaccine names, separated by commas. This records vaccination history; it does not prescribe a vaccine.',
            validator: (_) => _entries(vaccines).isEmpty
                ? 'Enter at least one vaccine type.'
                : null,
          ),
        ],
      ],
    ),
  );

  Widget _laboratorySection() => IntakeFormSection(
    number: '04',
    title: 'Laboratory results',
    subtitle: 'Optional · Attach up to 5 images, 750 KB each. Check that the text is readable.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField(
          controller: labNotes,
          label: 'Laboratory findings',
          hint: 'Add notes about the results',
          lines: 3,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _saving || _pickingImage || _labAttachments.length >= 5
                  ? null
                  : () => _pickLabImage(ImageSource.gallery),
              icon: const Icon(Icons.attach_file),
              label: const Text('Attach image'),
            ),
            if (kIsWeb ||
                defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)
              OutlinedButton.icon(
                onPressed:
                    _saving || _pickingImage || _labAttachments.length >= 5
                    ? null
                    : _scanLabResults,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan document'),
              ),
          ],
        ),
        if (_pickingImage) const LinearProgressIndicator(),
        for (final attachment in _labAttachments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Image.memory(
              attachment.bytes!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
            title: Text(
              attachment.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: InteractiveViewer(
                        child: Image.memory(attachment.bytes!),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
            trailing: IconButton(
              tooltip: 'Remove image',
              icon: const Icon(Icons.close),
              onPressed: _saving
                  ? null
                  : () => setState(() => _labAttachments.remove(attachment)),
            ),
          ),
      ],
    ),
  );

  Future<void> _recoverImage() async {
    try {
      final result = await ImagePicker().retrieveLostData();
      for (final file in result.files ?? <XFile>[]) {
        await _addLabImage(file);
      }
    } catch (_) {
      _imageError('Could not recover the photo. Please attach it again.');
    }
  }

  Future<void> _pickLabImage(ImageSource source) async {
    setState(() => _pickingImage = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file != null) await _addLabImage(file);
    } catch (_) {
      _imageError(
        'Could not open the image or camera. Check permissions and try again.',
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _scanLabResults() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      await _pickLabImage(ImageSource.camera);
      return;
    }

    setState(() => _pickingImage = true);
    try {
      final result = await FlutterDocScanner().getScannedDocumentAsImages(
        page: 5 - _labAttachments.length,
        imageFormat: ImageFormat.jpeg,
        quality: 0.75,
      );
      for (final path in result?.images ?? <String>[]) {
        if (!mounted) break;
        final uri = Uri.parse(path);
        final bytes = uri.scheme == 'content'
            ? await uri.getContent()
            : await XFile(uri.scheme == 'file' ? uri.toFilePath() : path)
                  .readAsBytes();
        await _addLabImageBytes(
          bytes,
          name: 'Lab scan ${_labAttachments.length + 1}.jpg',
          compress: true,
        );
      }
    } catch (_) {
      _imageError(
        'Could not scan the document. Check camera permission and try again.',
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _addLabImage(XFile file, {bool compress = false}) async {
    if (!compress && await file.length() > 750000) {
      _imageError('This image exceeds 750 KB. Choose a smaller image.');
      return;
    }
    await _addLabImageBytes(
      await file.readAsBytes(),
      name: file.name,
      compress: compress,
    );
  }

  Future<void> _addLabImageBytes(
    Uint8List imageBytes, {
    required String name,
    bool compress = false,
  }) async {
    var bytes = imageBytes;
    if (compress && bytes.length > 750000) {
      final original = img.decodeImage(bytes);
      if (original == null) {
        _imageError('Could not read the scanned image. Please scan it again.');
        return;
      }
      for (final longestSide in [2000, 1600, 1200, 900]) {
        final resized = original.width >= original.height
            ? (original.width > longestSide
                  ? img.copyResize(original, width: longestSide)
                  : original)
            : (original.height > longestSide
                  ? img.copyResize(original, height: longestSide)
                  : original);
        for (final quality in [85, 70, 55]) {
          bytes = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
          if (bytes.length <= 750000) break;
        }
        if (bytes.length <= 750000) break;
      }
    }
    if (bytes.length > 750000) {
      _imageError('This scan exceeds 750 KB. Try scanning one page at a time.');
      return;
    }
    final decoded = await decodeImageFromList(bytes);
    decoded.dispose();
    if (!mounted || _labAttachments.length >= 5) return;
    setState(
      () => _labAttachments.add(LabAttachment(name: name, bytes: bytes)),
    );
  }

  void _imageError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _consultationSection() => IntakeFormSection(
    number: '05',
    title: 'Consultation ticket',
    subtitle: 'Continue to a consultation for this patient after registration.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Create a consultation ticket'),
          subtitle: const Text(
            'Choose symptoms here, then add visit details and send to the doctor on the next screen.',
          ),
          value: _createTicket,
          onChanged: (value) => setState(() => _createTicket = value),
        ),
        if (_createTicket) ...[
          const Divider(height: 28),
          Text('Symptoms', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('Optional · Select all reported symptoms.'),
          const SizedBox(height: 16),
          SymptomSelector(
            selected: _symptoms,
            onChanged: (value) => setState(() => _symptoms = value),
          ),
        ],
      ],
    ),
  );

  Widget _emergencySection() => IntakeFormSection(
    icon: Icons.contact_phone_outlined,
    title: 'Emergency contact',
    subtitle: 'Optional · Someone to contact when needed.',
    child: Column(
      children: [
        _textField(
          controller: emergencyName,
          label: 'Contact name',
          hint: 'Full name',
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 20),
        _textField(
          key: _emergencyPhoneKey,
          controller: emergencyPhone,
          label: 'Contact phone',
          hint: 'e.g. 0917 123 4567',
          keyboardType: TextInputType.phone,
          validator: (value) =>
              value == null || value.trim().isEmpty ? null : _phoneError(value),
        ),
      ],
    ),
  );

  Widget _summarySection() => IntakeFormSection(
    icon: Icons.badge_outlined,
    title: 'Patient at a glance',
    subtitle: 'Details update as you fill in the form.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                _fullName.isEmpty ? 'Patient name' : _fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Patient ID assigned after registration',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _detail('Date of birth', birth.text),
        _detail('Phone', phone.text),
        _detail('Allergies', allergies.text),
        if (_createTicket)
          _detail(
            'Consultation ticket',
            '${_symptoms.length} symptoms selected',
          ),
        const Divider(height: 24),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.fact_check_outlined, size: 20, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Review all details and confirm patient consent before registering.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _paired(Widget firstField, Widget secondField) => LayoutBuilder(
    builder: (_, constraints) => constraints.maxWidth < 500
        ? Column(
            children: [firstField, const SizedBox(height: 20), secondField],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: firstField),
              const SizedBox(width: 16),
              Expanded(child: secondField),
            ],
          ),
  );

  Widget _textField({
    GlobalKey<FormFieldState<String>>? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helper,
    int lines = 1,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.sentences,
    String? Function(String?)? validator,
    Iterable<String>? autofillHints,
  }) => TextFormField(
    key: key,
    controller: controller,
    minLines: lines,
    maxLines: lines == 1 ? 1 : lines + 2,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    textInputAction: lines == 1
        ? TextInputAction.next
        : TextInputAction.newline,
    autofillHints: autofillHints,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      errorMaxLines: 2,
      floatingLabelBehavior: FloatingLabelBehavior.always,
    ),
  );

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final result = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? today,
      firstDate: DateTime(1900),
      lastDate: today,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select date of birth',
    );
    if (!mounted || result == null) return;
    setState(() {
      dateOfBirth = result;
      birth.text = MaterialLocalizations.of(context).formatMediumDate(result);
    });
    _birthKey.currentState?.validate();
  }

  String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  String? _phoneError(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Enter a phone number.';
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\+?[0-9 ()-]+$').hasMatch(input) ||
        digits.length < 7 ||
        digits.length > 15) {
      return 'Use 7–15 digits, with an optional country code.';
    }
    return null;
  }

  Widget _actions() => Container(
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
                final cancel = TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                );
                final review = FilledButton.icon(
                  onPressed: _saving || _pickingImage ? null : _review,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    _saving
                        ? 'Saving patient...'
                        : (_createTicket
                              ? 'Review & continue'
                              : 'Review & register'),
                  ),
                );
                if (constraints.maxWidth < 600) {
                  return OverflowBar(
                    spacing: 10,
                    overflowSpacing: 8,
                    alignment: MainAxisAlignment.spaceBetween,
                    overflowAlignment: OverflowBarAlignment.end,
                    children: [cancel, review],
                  );
                }
                return Row(
                  children: [
                    cancel,
                    const Spacer(),
                    Text(
                      _completed == 5
                          ? 'Required details complete'
                          : '$_completed of 5 required details',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 20),
                    review,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _review() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      for (final key in [
        _firstKey,
        _lastKey,
        _birthKey,
        _phoneKey,
        _addressKey,
        _emergencyPhoneKey,
        _vaccinesKey,
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
    var consent = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          constraints: const BoxConstraints(maxWidth: 540),
          icon: const Icon(
            Icons.fact_check_outlined,
            color: AppColors.primary,
            size: 32,
          ),
          title: const Text('Review patient details'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail('Patient name', _fullName),
                  _detail('Date of birth', birth.text),
                  _detail('Gender', gender),
                  _detail('Phone', phone.text),
                  _detail('Address', address.text),
                  const Divider(height: 24),
                  _detail('Medical history', history.text),
                  _detail('Vaccinated', vaccinationStatus),
                  if (vaccinationStatus == 'Yes')
                    _detail('Vaccine types', vaccines.text),
                  _detail('Laboratory findings', labNotes.text),
                  _detail(
                    'Laboratory images',
                    _labAttachments.map((file) => file.name).join('\n'),
                  ),
                  _detail('Allergies', _entries(allergies).join(', ')),
                  _detail(
                    'Existing conditions',
                    _entries(conditions).join(', '),
                  ),
                  _detail(
                    'Current medications',
                    _entries(medications).join(', '),
                  ),
                  _detail('Emergency contact', emergencyName.text),
                  _detail('Emergency phone', emergencyPhone.text),
                  if (_createTicket) ...[
                    const Divider(height: 24),
                    _detail(
                      'Consultation symptoms',
                      _symptoms.isEmpty
                          ? 'None selected'
                          : _symptoms.join(', '),
                    ),
                    const Text(
                      'Next: complete the visit details and review the ticket before sending. The patient will be registered now.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                  const Divider(height: 24),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: consent,
                    onChanged: (value) =>
                        updateDialog(() => consent = value ?? false),
                    title: const Text(
                      'Patient consent confirmed',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Confirm that the patient agreed to registration.',
                      style: TextStyle(fontSize: 12),
                    ),
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
              onPressed: consent
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: Text(
                _createTicket ? 'Register & continue' : 'Register patient',
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;
    final state = AppStateScope.of(context);
    final now = _registeredAt ??= DateTime.now();
    setState(() => _saving = true);
    try {
      _patientId ??= await state.database.newPatientId();
      if (!mounted) return;
      final patient = Patient(
        id: _patientId!,
        firstName: first.text.trim(),
        lastName: last.text.trim(),
        dateOfBirth: dateOfBirth!,
        gender: gender,
        phone: phone.text.trim(),
        address: address.text.trim(),
        allergies: _entries(allergies),
        conditions: _entries(conditions),
        medicalHistory: history.text.trim().isEmpty
            ? 'No medical history recorded.'
            : history.text.trim(),
        medications: _entries(medications),
        emergencyContactName: emergencyName.text.trim(),
        emergencyContactPhone: emergencyPhone.text.trim(),
        labs: labNotes.text.trim().isEmpty
            ? 'No laboratory findings recorded'
            : labNotes.text.trim(),
        vaccinationStatus: vaccinationStatus,
        vaccines: vaccinationStatus == 'Yes' ? _entries(vaccines) : [],
        labAttachments: List.of(_labAttachments),
        registeredAt: now,
      );
      final messenger = ScaffoldMessenger.of(context);
      await state.addPatient(patient);
      if (!mounted) return;
      if (_createTicket) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => TicketFormPage(
              initialPatient: patient,
              initialSymptoms: _symptoms.toList(),
            ),
          ),
        );
      } else {
        Navigator.pop(context);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('${patient.fullName} registered as ${patient.id}.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the patient. Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _entries(TextEditingController controller) => controller.text
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();

  Widget _detail(String label, String value) => Padding(
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
          value.trim().isEmpty ? 'Not recorded' : value.trim(),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
