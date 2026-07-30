import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';

/// Auswahl für Beziehungstypen im Stammbaum.
class RelationshipSelector extends StatelessWidget {
  const RelationshipSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String> onChanged;

  static const options = <String, String>{
    'parent': 'Elternteil von',
    'child': 'Kind von',
    'spouse': 'Ehepartner/in von',
    'sibling': 'Geschwister von',
    'partner': 'Partner/in von',
    'other': 'Andere Beziehung zu',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Beziehungstyp',
        filled: true,
        fillColor: AppColors.card,
      ),
      items: options.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
