import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'patient_profile_page.dart';
import 'register_patient_page.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});
  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final search = TextEditingController();
  final _searchKey = GlobalKey();
  String gender = 'All patients';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void register() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const RegisterPatientPage()),
  );

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = View.of(context).viewInsets.bottom > 0;
    final visibleHeight =
        MediaQuery.sizeOf(context).height -
        View.of(context).viewInsets.bottom / View.of(context).devicePixelRatio;
    final state = AppStateScope.of(context);
    final query = search.text.trim().toLowerCase();
    final results = state.patients.where((p) {
      return p.matchesSearch(query) &&
          (gender == 'All patients' || gender == p.gender);
    }).toList();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
        vertical: keyboardOpen
            ? 8
            : MediaQuery.sizeOf(context).width < 600
            ? 18
            : 28,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!keyboardOpen) ...[
                PageHeading(
                  title: 'Patient directory',
                  subtitle: 'A familiar face. A complete care history.',
                  action: FilledButton.icon(
                    onPressed: register,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Register patient'),
                  ),
                ),
                const SizedBox(height: 22),
              ],
              TextField(
                key: _searchKey,
                controller: search,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search last name, first name, ID or phone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(search.clear),
                          icon: const Icon(Icons.close_rounded, size: 19),
                        ),
                ),
              ),
              if (!keyboardOpen) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All patients', 'Female', 'Male']
                        .map(
                          (g) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                g,
                                style: TextStyle(
                                  color: gender == g
                                      ? AppColors.ink
                                      : AppColors.muted,
                                  fontWeight: gender == g
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              showCheckmark: false,
                              color: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return const Color(0xFFE4E8EF);
                                }
                                return const Color(0xFFF0F2F5);
                              }),
                              selected: gender == g,
                              onSelected: (_) => setState(() => gender = g),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${results.length} ${results.length == 1 ? 'patient' : 'patients'} found',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: keyboardOpen
                    ? (visibleHeight.clamp(0.0, constraints.maxHeight) -
                              MediaQuery.textScalerOf(context).scale(80))
                          .clamp(48.0, 500.0)
                    : constraints.maxHeight < 500
                    ? 300
                    : constraints.maxHeight - 250,
                child: results.isEmpty
                    ? keyboardOpen
                          ? const Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('No patient found'),
                              ),
                            )
                          : SingleChildScrollView(
                              child: EmptyState(
                                title: 'No patient found',
                                message: 'Try a different name or register a new patient.',
                                action: FilledButton(
                                  onPressed: register,
                                  child: const Text('Register new patient'),
                                ),
                              ),
                            )
                    : Card(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, index) => const Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                            ),
                            itemBuilder: (_, i) {
                              final p = results[i];
                              return InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PatientProfilePage(patient: p),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: LayoutBuilder(
                                    builder: (_, c) => Row(
                                      children: [
                                        PatientAvatar(
                                          initials: p.initials,
                                          radius: 23,
                                        ),
                                        const SizedBox(width: 13),
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.fullName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.ink,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                p.id,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                              if (c.maxWidth < 700) ...[
                                                const SizedBox(height: 5),
                                                Text(
                                                  '${p.age} years · ${p.gender} · ${p.phone}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (c.maxWidth >= 700) ...[
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '${p.age} years · ${p.gender}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              p.phone,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              p.consultations.isEmpty
                                                  ? 'No previous visits'
                                                  : shortDate(
                                                      p
                                                          .consultations
                                                          .first
                                                          .date,
                                                    ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 20,
                                          color: AppColors.muted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
