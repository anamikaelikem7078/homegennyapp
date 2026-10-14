import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../care/domain/cook_models.dart';
import '../../../../care/presentation/care_providers.dart';
import '../../../../care/presentation/care_widgets.dart';
import '../../navigation/staff_routes.dart';

void _backOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(StaffRoutes.home);
  }
}

(String, Color) _menuLook(MenuItem m) => switch (m.status) {
      MenuStatus.suggested => ('Waiting for family', AppColors.warning),
      MenuStatus.approved => ('Approved', AppColors.success),
      MenuStatus.rejected => ('Declined', AppColors.error),
      _ => ('From the family', AppColors.primary),
    };

Widget _stars(int rating) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= rating ? Icons.star_rounded : Icons.star_border_rounded, size: 16, color: const Color(0xFFF59E0B)),
      ],
    );

// ---------------------------------------------------------------------------
// Home card
// ---------------------------------------------------------------------------

class StaffCookHomeCard extends ConsumerWidget {
  const StaffCookHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(cookTodayProvider).valueOrNull;
    if (today == null || today.placements.isEmpty) return const SizedBox.shrink();
    final planned = today.placements.expand((p) => p.meals).where((m) => m.menu != null).length;
    final logged = today.placements.expand((p) => p.meals).where((m) => m.log != null).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DsListCard(
        icon: Icons.soup_kitchen_rounded,
        title: 'Today\'s kitchen',
        subtitle: '$planned meal${planned == 1 ? '' : 's'} on the menu · $logged logged',
        margin: EdgeInsets.zero,
        onTap: () => context.push(StaffRoutes.cookToday),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today
// ---------------------------------------------------------------------------

class StaffCookTodayScreen extends ConsumerWidget {
  const StaffCookTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cookTodayProvider);
    return DsPage(
      title: 'Today\'s kitchen',
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(cookTodayProvider),
      body: dsAsyncBody(
        async,
        onRetry: () => ref.invalidate(cookTodayProvider),
        builder: (today) {
          if (today.placements.isEmpty) {
            return const [
              DsEmptyBlock(
                icon: Icons.soup_kitchen_rounded,
                title: 'No kitchen today',
                message: 'When you are cooking for a family, their menu and food profile show here.',
              ),
            ];
          }
          return [
            for (final p in today.placements) _CookPlacementView(placement: p, multiple: today.placements.length > 1),
          ];
        },
      ),
    );
  }
}

class _CookPlacementView extends ConsumerWidget {
  const _CookPlacementView({required this.placement, required this.multiple});
  final CookPlacement placement;
  final bool multiple;

  Future<void> _log(BuildContext context, WidgetRef ref, CookMealSlot slot) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StaffLogMealScreen(placementId: placement.placementId, slot: slot)),
    );
    if (ok == true) ref.invalidate(cookTodayProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = placement;
    final r = p.rating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (multiple) DsSection(p.clientName),
        _FoodProfileCard(profile: p.foodProfile),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DsOutlineButton(
                label: 'Suggest menu',
                icon: Icons.lightbulb_outline_rounded,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _SuggestSheet(placementId: p.placementId),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DsOutlineButton(
                label: r.avg7d != null ? 'Rating ${r.avg7d}/5' : 'Ratings',
                icon: Icons.star_rounded,
                onPressed: () => context.push(StaffRoutes.cookRatings(p.placementId)),
              ),
            ),
          ],
        ),
        const DsSection('Today\'s meals'),
        for (final slot in p.meals) _MealSlotCard(slot: slot, onLog: () => _log(context, ref, slot)),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// The household profile; allergies in red.
class _FoodProfileCard extends StatelessWidget {
  const _FoodProfileCard({required this.profile});
  final FoodProfile? profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) {
      return const DsNote(text: 'The family has not filled in their food profile yet. Ask them about diet and allergies.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p.allergies.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.error)),
            child: Row(
              children: [
                const Icon(Icons.dangerous_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Allergies: ${p.allergies.join(', ')}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        DsInfoCard(
          lines: [
            if (p.dietType != null) DsInfoLine(Icons.eco_rounded, 'Diet', carePretty(p.dietType!)),
            if (p.spiceLevel != null) DsInfoLine(Icons.local_fire_department_rounded, 'Spice', '${p.spiceLevel} of 5'),
            if (p.salt != null || p.oil != null)
              DsInfoLine(Icons.opacity_rounded, 'Salt / oil', '${carePretty(p.salt ?? 'NORMAL')} salt · ${carePretty(p.oil ?? 'NORMAL')} oil'),
            if (p.healthConditions.isNotEmpty) DsInfoLine(Icons.favorite_rounded, 'Health', p.healthConditions.map(carePretty).join(', ')),
            if (p.cuisines.isNotEmpty) DsInfoLine(Icons.restaurant_menu_rounded, 'Cuisines', p.cuisines.join(', ')),
            if (p.dislikes != null) DsInfoLine(Icons.thumb_down_alt_rounded, 'Dislikes', p.dislikes!),
            if (p.familySize != null) DsInfoLine(Icons.groups_rounded, 'People', '${p.familySize}'),
            if (p.notes != null) DsInfoLine(Icons.edit_note_rounded, 'Notes', p.notes!),
          ],
        ),
      ],
    );
  }
}

class _MealSlotCard extends StatelessWidget {
  const _MealSlotCard({required this.slot, required this.onLog});
  final CookMealSlot slot;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final m = slot.menu;
    final log = slot.log;
    final look = m == null ? null : _menuLook(m);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsIconTile(log != null ? Icons.check_circle_rounded : Icons.restaurant_rounded, size: 38, color: log != null ? AppColors.success : null),
              const SizedBox(width: 10),
              Expanded(
                child: Text(carePretty(slot.meal), style: GoogleFonts.plusJakartaSans(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
              ),
              if (look != null) DsPill(look.$1, color: look.$2),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            m == null ? 'No menu set — cook what suits the family' : m.dishText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: m == null ? FontWeight.w500 : FontWeight.w700,
              color: m == null ? AppColors.lightTextSecondary : AppColors.lightTextPrimary,
            ),
          ),
          if (m?.specialInstruction != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10)),
              child: Text('Family\'s note: ${m!.specialInstruction}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          if (m?.status == MenuStatus.rejected && m?.rejectReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Family declined: ${m!.rejectReason}', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.error)),
            ),
          if (m != null && m.healthWarnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Check: ${m.healthWarnings.join(' · ')}', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.warning, fontWeight: FontWeight.w700)),
            ),
          if (log != null) ...[
            const SizedBox(height: 8),
            Text(
              'You logged: ${log.dishes.map((d) => d.name).join(', ')}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.success, fontWeight: FontWeight.w700),
            ),
            if (log.feedback != null)
              Row(children: [_stars(log.feedback!.rating), const SizedBox(width: 6), Text('from the family', style: GoogleFonts.plusJakartaSans(fontSize: 12))]),
          ],
          const SizedBox(height: 12),
          log == null
              ? DsGradientButton(label: 'Log meal', icon: Icons.add_a_photo_rounded, onPressed: onLog)
              : DsOutlineButton(label: 'Update log', onPressed: onLog),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Log meal
// ---------------------------------------------------------------------------

class _DishRow {
  _DishRow({String name = '', this.spice, this.photoId}) : controller = TextEditingController(text: name);
  final TextEditingController controller;
  int? spice;
  String? photoId;
}

class StaffLogMealScreen extends ConsumerStatefulWidget {
  const StaffLogMealScreen({super.key, required this.placementId, required this.slot});
  final String placementId;
  final CookMealSlot slot;

  @override
  ConsumerState<StaffLogMealScreen> createState() => _StaffLogMealScreenState();
}

class _StaffLogMealScreenState extends ConsumerState<StaffLogMealScreen> {
  late final List<_DishRow> _rows = [
    if (widget.slot.log != null)
      for (final d in widget.slot.log!.dishes) _DishRow(name: d.name, spice: d.spiceLevel, photoId: d.photoFileId)
    else if (widget.slot.menu != null)
      for (final d in widget.slot.menu!.dishes) _DishRow(name: d.name),
  ];
  late final _servings = TextEditingController(text: widget.slot.log?.servings?.toString());
  late final _notes = TextEditingController(text: widget.slot.log?.notes);
  bool _saving = false;
  int? _uploadingRow;

  @override
  void initState() {
    super.initState();
    if (_rows.isEmpty) _rows.add(_DishRow());
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.controller.dispose();
    }
    _servings.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _photo(int i) async {
    setState(() => _uploadingRow = i);
    final id = await carePickAndUpload(context, ref, placementId: widget.placementId);
    if (!mounted) return;
    setState(() {
      _uploadingRow = null;
      if (id != null) _rows[i].photoId = id;
    });
  }

  Future<void> _save() async {
    final dishes = [
      for (final r in _rows)
        if (r.controller.text.trim().isNotEmpty) LoggedDish(name: r.controller.text.trim(), spiceLevel: r.spice, photoFileId: r.photoId),
    ];
    if (dishes.isEmpty) {
      context.showDsSnackBar('Add at least one dish.', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(careApiProvider).logMeal(
          pid: widget.placementId,
          meal: widget.slot.meal,
          dishes: dishes,
          servings: int.tryParse(_servings.text.trim()),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('${carePretty(widget.slot.meal)} logged — the family has been told', type: DsSnackBarType.success);
        Navigator.of(context).pop(true);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) => DsPage(
        title: 'Log ${carePretty(widget.slot.meal).toLowerCase()}',
        onBack: () => Navigator.of(context).pop(false),
        bottom: DsGradientButton(label: 'Save', icon: Icons.check_rounded, isLoading: _saving, onPressed: _saving || _uploadingRow != null ? null : _save),
        body: [
          const DsSection('Dishes', top: 4),
          for (var i = 0; i < _rows.length; i++)
            Container(
              key: ObjectKey(_rows[i]),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: dsCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DsLabeledField(label: 'Dish', controller: _rows[i].controller, hint: 'e.g. Dal', textCapitalization: TextCapitalization.words),
                      ),
                      if (_rows.length > 1)
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          onPressed: () {
                            final removed = _rows[i];
                            setState(() => _rows.removeAt(i));
                            WidgetsBinding.instance.addPostFrameCallback((_) => removed.controller.dispose());
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Spice (optional)', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var s = 1; s <= 5; s++)
                        DsChoiceChip(label: '$s', selected: _rows[i].spice == s, onTap: () => setState(() => _rows[i].spice = _rows[i].spice == s ? null : s)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_rows[i].photoId != null) ...[
                        CareFileImage(fileId: _rows[i].photoId!, size: 56),
                        const SizedBox(width: 10),
                      ],
                      TextButton.icon(
                        onPressed: _uploadingRow != null ? null : () => _photo(i),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: Text(_uploadingRow == i ? 'Uploading…' : (_rows[i].photoId == null ? 'Add photo (optional)' : 'Change photo')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _rows.add(_DishRow())),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add dish'),
            ),
          ),
          const SizedBox(height: 8),
          DsLabeledField(
            label: 'Servings',
            controller: _servings,
            icon: Icons.groups_rounded,
            optional: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          DsLabeledField(label: 'Notes', controller: _notes, icon: Icons.edit_note_rounded, optional: true, textCapitalization: TextCapitalization.sentences),
        ],
      );
}

// ---------------------------------------------------------------------------
// Suggest menu
// ---------------------------------------------------------------------------

class _SuggestSheet extends ConsumerStatefulWidget {
  const _SuggestSheet({required this.placementId});
  final String placementId;

  @override
  ConsumerState<_SuggestSheet> createState() => _SuggestSheetState();
}

class _SuggestSheetState extends ConsumerState<_SuggestSheet> {
  late String _date = careTodayIst();
  String _meal = CookEnums.meals[1];
  final _dishes = TextEditingController();
  final _notes = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _dishes.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = careNowIst();
    final today = DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(context: context, initialDate: DateTime.parse(_date), firstDate: today, lastDate: today.add(const Duration(days: 20)));
    if (d != null) setState(() => _date = careYmd(d));
  }

  Future<void> _send() async {
    final dishes = [for (final l in _dishes.text.split('\n')) if (l.trim().isNotEmpty) l.trim()];
    setState(() => _sending = true);
    final result = await ref.read(careApiProvider).suggestMenu(widget.placementId, [
      {'date': _date, 'meal': _meal, 'dishes': dishes, if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim()},
    ]);
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Sent to the family for approval', type: DsSnackBarType.success);
        ref.invalidate(cookTodayProvider);
        Navigator.of(context).pop();
      },
      // e.g. "2026-10-14 lunch is already set by the family."
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _dishes.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Suggest a menu', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
                const SizedBox(height: 12),
                DsListCard(icon: Icons.event_rounded, title: _date == careTodayIst() ? 'Today' : _date, subtitle: 'Tap to change the day', onTap: _pickDate),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final m in CookEnums.meals) DsChoiceChip(label: carePretty(m), selected: _meal == m, onTap: () => setState(() => _meal = m))],
                ),
                const SizedBox(height: 12),
                DsLabeledField(
                  label: 'Dishes (one per line)',
                  controller: _dishes,
                  icon: Icons.restaurant_rounded,
                  hint: 'Rajma\nRice\nSalad',
                  maxLines: 6,
                  minLines: 3,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DsLabeledField(label: 'Note', controller: _notes, optional: true, textCapitalization: TextCapitalization.sentences),
                const SizedBox(height: 16),
                DsGradientButton(label: 'Send to family', icon: Icons.send_rounded, isLoading: _sending, onPressed: !ready || _sending ? null : _send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ratings
// ---------------------------------------------------------------------------

class StaffCookRatingsScreen extends ConsumerWidget {
  const StaffCookRatingsScreen({super.key, required this.placementId});
  final String placementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (pid: placementId, days: 30);
    final async = ref.watch(mealsProvider(key));
    return DsPage(
      title: 'Family ratings',
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(mealsProvider(key)),
      body: dsAsyncBody(
        async,
        onRetry: () => ref.invalidate(mealsProvider(key)),
        builder: (v) {
          final rated = v.items.where((m) => m.feedback != null).toList();
          return [
            DsListCard(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: v.rating.avg7d != null ? '${v.rating.avg7d} / 5 this week' : 'No ratings this week',
              subtitle: v.rating.avg30d != null ? '${v.rating.avg30d} / 5 over 30 days (${v.rating.count30d} ratings)' : 'Ratings show here when the family rates a meal',
            ),
            for (final m in rated)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: dsCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('${carePretty(m.meal)} · ${m.date}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
                        ),
                        _stars(m.feedback!.rating),
                      ],
                    ),
                    Text(m.dishes.map((d) => d.name).join(', '), style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.lightTextSecondary)),
                    if (m.feedback!.tags.isNotEmpty || m.feedback!.comment != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          [...m.feedback!.tags.map(carePretty), if (m.feedback!.comment != null) '"${m.feedback!.comment}"'].join(' · '),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                        ),
                      ),
                  ],
                ),
              ),
          ];
        },
      ),
    );
  }
}
