import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/features/map/data/map_filter_state.dart';
import 'package:memory_ai/features/memories/data/person_model.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';

/// Bottom-Sheet für kombinierbare Kartenfilter.
class MapFilterSheet extends StatefulWidget {
  const MapFilterSheet({
    super.key,
    required this.initial,
    required this.availableYears,
    required this.people,
    this.continents = const [
      'Europe',
      'Asia',
      'Africa',
      'North America',
      'South America',
      'Oceania',
      'Antarctica',
    ],
  });

  final MapFilterState initial;
  final List<int> availableYears;
  final List<PersonModel> people;
  final List<String> continents;

  static Future<MapFilterState?> show(
    BuildContext context, {
    required MapFilterState initial,
    required List<int> availableYears,
    required List<PersonModel> people,
  }) {
    return showModalBottomSheet<MapFilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Theme(
        data: Theme.of(ctx).copyWith(
          chipTheme: Theme.of(ctx).chipTheme.copyWith(
            selectedColor: AppColors.turquoise.withValues(alpha: 0.25),
            checkmarkColor: AppColors.turquoise,
            side: BorderSide(color: AppColors.divider.withValues(alpha: 0.6)),
            labelStyle: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.85,
          child: MapFilterSheet(
            initial: initial,
            availableYears: availableYears,
            people: people,
          ),
        ),
      ),
    );
  }

  @override
  State<MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<MapFilterSheet> {
  late MapFilterState _filter;
  late final TextEditingController _query;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _region;

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
    _query = TextEditingController(text: _filter.locationQuery ?? '');
    _city = TextEditingController(text: _filter.city ?? '');
    _country = TextEditingController(text: _filter.country ?? '');
    _region = TextEditingController(text: _filter.region ?? '');
  }

  @override
  void dispose() {
    _query.dispose();
    _city.dispose();
    _country.dispose();
    _region.dispose();
    super.dispose();
  }

  void _syncText() {
    _filter = _filter.copyWith(
      locationQuery: _query.text.trim().isEmpty ? null : _query.text.trim(),
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      country: _country.text.trim().isEmpty ? null : _country.text.trim(),
      region: _region.text.trim().isEmpty ? null : _region.text.trim(),
      clearLocationQuery: _query.text.trim().isEmpty,
      clearCity: _city.text.trim().isEmpty,
      clearCountry: _country.text.trim().isEmpty,
      clearRegion: _region.text.trim().isEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                children: [
                  TextField(
                    controller: _query,
                    decoration: const InputDecoration(
                      labelText: 'Standort (Freitext)',
                    ),
                  ),
                  TextField(
                    controller: _city,
                    decoration: const InputDecoration(labelText: 'Stadt'),
                  ),
                  TextField(
                    controller: _region,
                    decoration: const InputDecoration(labelText: 'Region'),
                  ),
                  TextField(
                    controller: _country,
                    decoration: const InputDecoration(labelText: 'Land'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Kontinent',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Wrap(
                    spacing: 6,
                    children: widget.continents.map((c) {
                      final selected = _filter.continent == c;
                      return FilterChip(
                        label: Text(c),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            _filter = _filter.copyWith(
                              continent: v ? c : null,
                              clearContinent: !v,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Jahre', style: Theme.of(context).textTheme.labelLarge),
                  Wrap(
                    spacing: 6,
                    children: widget.availableYears.map((y) {
                      final selected = _filter.years.contains(y);
                      return FilterChip(
                        label: Text('$y'),
                        selected: selected,
                        onSelected: (v) {
                          final next = {..._filter.years};
                          if (v) {
                            next.add(y);
                          } else {
                            next.remove(y);
                          }
                          setState(
                            () => _filter = _filter.copyWith(years: next),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Quartale',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  ...widget.availableYears.map((y) {
                    return Row(
                      children: [
                        SizedBox(width: 48, child: Text('$y')),
                        ...List.generate(4, (i) {
                          final q = i + 1;
                          final f = QuarterFilter(y, q);
                          final selected = _filter.quarters.contains(f);
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: FilterChip(
                              label: Text('Q$q'),
                              selected: selected,
                              onSelected: (v) {
                                final next = {..._filter.quarters};
                                if (v) {
                                  next.add(f);
                                } else {
                                  next.remove(f);
                                }
                                setState(
                                  () => _filter = _filter.copyWith(
                                    quarters: next,
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Personen',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  SwitchListTile(
                    title: const Text('Nur ich'),
                    value: _filter.onlyMe,
                    onChanged: (v) =>
                        setState(() => _filter = _filter.copyWith(onlyMe: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Ohne Personen'),
                    value: _filter.withoutPeople,
                    onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(withoutPeople: v),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Unbekannte Personen'),
                    value: _filter.unknownPeopleOnly,
                    onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(unknownPeopleOnly: v),
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: widget.people.map((p) {
                      final selected = _filter.personIds.contains(p.id);
                      return FilterChip(
                        label: Text(p.name),
                        selected: selected,
                        onSelected: (v) {
                          final next = {..._filter.personIds};
                          if (v) {
                            next.add(p.id);
                          } else {
                            next.remove(p.id);
                          }
                          setState(
                            () => _filter = _filter.copyWith(personIds: next),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Medientyp',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      FilterChip(
                        label: const Text('Alle'),
                        selected: _filter.mediaType == null,
                        onSelected: (_) => setState(
                          () =>
                              _filter = _filter.copyWith(clearMediaType: true),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Fotos'),
                        selected: _filter.mediaType == 'image',
                        onSelected: (_) => setState(
                          () => _filter = _filter.copyWith(mediaType: 'image'),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Videos'),
                        selected: _filter.mediaType == 'video',
                        onSelected: (_) => setState(
                          () => _filter = _filter.copyWith(mediaType: 'video'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Quelle', style: Theme.of(context).textTheme.labelLarge),
                  Wrap(
                    spacing: 6,
                    children: MapMediaSource.values.map((s) {
                      return FilterChip(
                        label: Text(s.labelDe),
                        selected: _filter.source == s,
                        onSelected: (_) => setState(
                          () => _filter = _filter.copyWith(source: s),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'Filter anwenden',
              onPressed: () {
                _syncText();
                Navigator.pop(context, _filter);
              },
            ),
          ],
        ),
      ),
    );
  }
}
