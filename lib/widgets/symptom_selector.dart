import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/mock_data.dart';

/// Shared symptom search and selection for registration and consultation.
class SymptomSelector extends StatefulWidget {
  const SymptomSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<SymptomSelector> createState() => _SymptomSelectorState();
}

class _SymptomSelectorState extends State<SymptomSelector> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(String symptom, bool value) {
    final next = {...widget.selected};
    value ? next.add(symptom) : next.remove(symptom);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final groups = symptomGroups.entries
        .map(
          (group) => MapEntry(
            group.key,
            group.value
                .where((symptom) => symptom.toLowerCase().contains(query))
                .toList(),
          ),
        )
        .where((group) => group.value.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search symptoms',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear symptom search',
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.selected.length} selected',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => widget.onChanged(<String>{}),
                child: const Text('Clear all'),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.selected
                .map(
                  (symptom) => InputChip(
                    label: Text(symptom),
                    labelStyle: const TextStyle(color: AppColors.primaryDark),
                    backgroundColor: const Color(0xFFEAF0FD),
                    onDeleted: () => _select(symptom, false),
                    deleteButtonTooltipMessage: 'Remove $symptom',
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        if (groups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No matching symptoms. Try another term.'),
          ),
        for (final group in groups)
          if (query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _chips(group.value),
                ],
              ),
            )
          else
            ExpansionTile(
              key: PageStorageKey('symptoms-${group.key}'),
              initiallyExpanded: group.key == 'General',
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 14),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                group.key,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _chips(group.value),
                ),
              ],
            ),
      ],
    );
  }

  Widget _chips(List<String> symptoms) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: symptoms
        .map(
          (symptom) => FilterChip(
            label: Text(symptom),
            labelStyle: TextStyle(
              color: widget.selected.contains(symptom)
                  ? AppColors.primaryDark
                  : AppColors.ink,
            ),
            selected: widget.selected.contains(symptom),
            onSelected: (value) => _select(symptom, value),
          ),
        )
        .toList(),
  );
}
