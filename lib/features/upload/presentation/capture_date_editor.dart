import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';

/// Datum- und optional Uhrzeit-Editor für Upload/Detail.
class CaptureDateEditor extends StatefulWidget {
  const CaptureDateEditor({
    super.key,
    this.initialDate,
    this.includeTime = true,
    required this.onConfirm,
  });

  final DateTime? initialDate;
  final bool includeTime;
  final ValueChanged<DateTime> onConfirm;

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    bool includeTime = true,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => CaptureDateEditor(
        initialDate: initialDate,
        includeTime: includeTime,
        onConfirm: (d) => Navigator.pop(ctx, d),
      ),
    );
  }

  @override
  State<CaptureDateEditor> createState() => _CaptureDateEditorState();
}

class _CaptureDateEditorState extends State<CaptureDateEditor> {
  late DateTime _date;
  late TimeOfDay _time;
  bool _withTime = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _date = DateTime(initial.year, initial.month, initial.day);
    _time = TimeOfDay.fromDateTime(initial);
    _withTime = widget.includeTime;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _confirm() {
    final result = _withTime
        ? DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute)
        : DateTime(_date.year, _date.month, _date.day);
    widget.onConfirm(result);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aufnahmedatum',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_date.day.toString().padLeft(2, '0')}.'
                '${_date.month.toString().padLeft(2, '0')}.'
                '${_date.year}',
              ),
              onTap: _pickDate,
            ),
            SwitchListTile(
              title: const Text('Uhrzeit festlegen'),
              value: _withTime,
              onChanged: (v) => setState(() => _withTime = v),
            ),
            if (_withTime)
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(_time.format(context)),
                onTap: _pickTime,
              ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'Übernehmen', onPressed: _confirm),
          ],
        ),
      ),
    );
  }
}
