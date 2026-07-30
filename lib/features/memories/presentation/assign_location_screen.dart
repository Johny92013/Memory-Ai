import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/map/data/media_location_enrichment_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';

/// Manuelle Ortszuordnung für ein bestehendes Foto.
class AssignLocationScreen extends StatefulWidget {
  const AssignLocationScreen({super.key, required this.mediaItem});

  final MediaItemModel mediaItem;

  @override
  State<AssignLocationScreen> createState() => _AssignLocationScreenState();
}

class _AssignLocationScreenState extends State<AssignLocationScreen> {
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _nameController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _latController.text = widget.mediaItem.latitude?.toStringAsFixed(6) ?? '';
    _lonController.text = widget.mediaItem.longitude?.toStringAsFixed(6) ?? '';
    _nameController.text = widget.mediaItem.locationName ?? '';
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat == null || lon == null) {
      setState(() => _error = 'Bitte gültige Koordinaten eingeben.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await MediaLocationEnrichmentService().updateManualLocation(
        mediaId: widget.mediaItem.id,
        latitude: lat,
        longitude: lon,
        locationName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ErrorMapper.map(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ort zuweisen',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.mediaItem.hasGps)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Dieses Foto enthält keine Standortdaten. Du kannst einen Ort manuell zuweisen.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _latController,
              label: 'Breitengrad',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _lonController,
              label: 'Längengrad',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _nameController,
              label: 'Standortname (optional)',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.accentPink),
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: _saving ? 'Speichern …' : 'Speichern',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
