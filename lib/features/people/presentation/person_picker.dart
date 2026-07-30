import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/family/data/family_member_model.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/features/memories/data/people_repository.dart';
import 'package:memory_ai/features/memories/data/person_model.dart';
import 'package:memory_ai/features/profile/data/profile_repository.dart';

/// Personenauswahl: Ich, Familienmitglieder, bestehende people, neu anlegen.
class PersonPicker extends StatefulWidget {
  const PersonPicker({
    super.key,
    this.peopleRepository,
    this.familyRepository,
    this.multiSelect = false,
    this.preselectedIds = const {},
    this.familyId,
  });

  final PeopleRepository? peopleRepository;
  final FamilyRepository? familyRepository;
  final bool multiSelect;
  final Set<String> preselectedIds;
  final String? familyId;

  static Future<List<PersonModel>?> show(
    BuildContext context, {
    bool multiSelect = false,
    Set<String> preselectedIds = const {},
    String? familyId,
  }) {
    return showModalBottomSheet<List<PersonModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.75,
        child: PersonPicker(
          multiSelect: multiSelect,
          preselectedIds: preselectedIds,
          familyId: familyId,
        ),
      ),
    );
  }

  @override
  State<PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends State<PersonPicker> {
  late final PeopleRepository _peopleRepo;
  late final FamilyRepository _familyRepo;
  final _nameController = TextEditingController();

  List<PersonModel> _people = [];
  List<FamilyMemberModel> _members = [];
  final Set<String> _selected = {};
  bool _loading = true;
  String? _selfName;

  @override
  void initState() {
    super.initState();
    _peopleRepo = widget.peopleRepository ?? PeopleRepository();
    _familyRepo = widget.familyRepository ?? FamilyRepository();
    _selected.addAll(widget.preselectedIds);
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final people = await _peopleRepo.listMyPeople();
      var members = <FamilyMemberModel>[];
      String? familyId = widget.familyId;
      if (familyId == null) {
        final families = await _familyRepo.listMyFamilies();
        if (families.isNotEmpty) familyId = families.first.id;
      }
      if (familyId != null) {
        members = await _familyRepo.listMembers(familyId);
      }
      String? selfName;
      try {
        final profile = await ProfileRepository().getMyProfile();
        selfName = profile?.displayName;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _people = people;
        _members = members;
        _selfName = selfName;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickSelf() async {
    try {
      final person = await _peopleRepo.findOrCreateSelf(displayName: _selfName);
      _select(person);
    } catch (e) {
      _snack(ErrorMapper.map(e).message);
    }
  }

  Future<void> _pickMember(FamilyMemberModel member) async {
    try {
      final person = await _peopleRepo.findOrCreateNamedPerson(
        member.displayName,
      );
      _select(person);
    } catch (e) {
      _snack(ErrorMapper.map(e).message);
    }
  }

  Future<void> _create() async {
    try {
      final person = await _peopleRepo.createPerson(_nameController.text);
      _select(person);
    } catch (e) {
      _snack(ErrorMapper.map(e).message);
    }
  }

  void _select(PersonModel person) {
    if (widget.multiSelect) {
      setState(() {
        if (_selected.contains(person.id)) {
          _selected.remove(person.id);
        } else {
          _selected.add(person.id);
        }
        if (_people.every((p) => p.id != person.id)) {
          _people = [..._people, person];
        }
      });
    } else {
      Navigator.pop(context, [person]);
    }
  }

  void _confirmMulti() {
    final chosen = _people.where((p) => _selected.contains(p.id)).toList();
    Navigator.pop(context, chosen);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = SupabaseService.client.auth.currentUser?.id;
    final otherMembers = _members.where((m) => m.userId != uid).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.multiSelect ? 'Personen auswählen' : 'Person zuordnen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(_selfName ?? 'Ich'),
                      subtitle: const Text('Mich selbst zuordnen'),
                      onTap: _pickSelf,
                    ),
                    if (otherMembers.isNotEmpty) ...[
                      const Divider(),
                      Text(
                        'Familienmitglieder',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      ...otherMembers.map(
                        (m) => ListTile(
                          leading: const Icon(Icons.family_restroom),
                          title: Text(m.displayName),
                          subtitle: Text(m.role.labelDe),
                          onTap: () => _pickMember(m),
                        ),
                      ),
                    ],
                    const Divider(),
                    Text(
                      'Gespeicherte Personen',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (_people.isEmpty)
                      const ListTile(
                        title: Text('Noch keine Personen angelegt.'),
                      )
                    else
                      ..._people.map((p) {
                        final selected = _selected.contains(p.id);
                        return ListTile(
                          leading: widget.multiSelect
                              ? Checkbox(
                                  value: selected,
                                  onChanged: (_) => _select(p),
                                )
                              : const Icon(Icons.person_outline),
                          title: Text(p.name),
                          onTap: () => _select(p),
                        );
                      }),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Neue Person ohne App-Account',
                        hintText: 'Name',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: _create,
                      child: const Text('Person anlegen'),
                    ),
                  ],
                ),
              ),
            if (widget.multiSelect) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: _selected.isEmpty ? null : _confirmMulti,
                child: Text('${_selected.length} übernehmen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
