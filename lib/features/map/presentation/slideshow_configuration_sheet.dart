import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/features/map/data/memory_album_session.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';

class SlideshowConfigurationSheet extends StatefulWidget {
  const SlideshowConfigurationSheet({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.locationLabel,
  });

  final List<MediaItemModel> items;
  final Set<String> selectedIds;
  final String locationLabel;

  static Future<SlideshowSession?> show(
    BuildContext context, {
    required List<MediaItemModel> items,
    required Set<String> selectedIds,
    required String locationLabel,
  }) {
    return showModalBottomSheet<SlideshowSession>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.55,
        child: SlideshowConfigurationSheet(
          items: items,
          selectedIds: selectedIds,
          locationLabel: locationLabel,
        ),
      ),
    );
  }

  @override
  State<SlideshowConfigurationSheet> createState() =>
      _SlideshowConfigurationSheetState();
}

class _SlideshowConfigurationSheetState
    extends State<SlideshowConfigurationSheet> {
  bool _useSelection = false;
  int _seconds = 3;
  bool _captions = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Slideshow / Video',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SwitchListTile(
              title: const Text('Nur Auswahl verwenden'),
              value: _useSelection,
              onChanged: widget.selectedIds.isEmpty
                  ? null
                  : (v) => setState(() => _useSelection = v),
            ),
            ListTile(
              title: Text('Dauer pro Bild: $_seconds s'),
              subtitle: Slider(
                value: _seconds.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) => setState(() => _seconds = v.round()),
              ),
            ),
            SwitchListTile(
              title: const Text('Datum / Ort einblenden'),
              value: _captions,
              onChanged: (v) => setState(() => _captions = v),
            ),
            const Spacer(),
            AppButton(
              label: 'Abspielen',
              onPressed: () {
                var items = List<MediaItemModel>.from(widget.items);
                if (_useSelection && widget.selectedIds.isNotEmpty) {
                  items = items
                      .where((i) => widget.selectedIds.contains(i.id))
                      .toList();
                }
                items.sort((a, b) {
                  final ad = a.takenAt ?? a.createdAt ?? DateTime(0);
                  final bd = b.takenAt ?? b.createdAt ?? DateTime(0);
                  return ad.compareTo(bd);
                });
                Navigator.pop(
                  context,
                  SlideshowSession(
                    items: items,
                    secondsPerImage: _seconds,
                    showCaptions: _captions,
                    locationLabel: widget.locationLabel,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
