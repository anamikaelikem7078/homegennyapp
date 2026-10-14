import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../care/domain/cook_models.dart';
import '../../../../care/presentation/care_providers.dart';
import '../../../../care/presentation/care_widgets.dart';
import '../../navigation/client_routes.dart';

void _backOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(ClientRoutes.dashboard);
  }
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _dayLabel(String ymd) {
  final d = DateTime.tryParse(ymd);
  if (d == null) return ymd;
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

(String, Color) _menuStatusLook(MenuItem m) => switch (m.status) {
      MenuStatus.suggested => ('Cook suggests', AppColors.warning),
      MenuStatus.approved => ('Approved', AppColors.success),
      MenuStatus.rejected => ('Declined', AppColors.error),
      _ => ('Planned', AppColors.primary),
    };

/// Yellow "check this" note for a menu's health warnings. Never blocks.
class MenuHealthWarnings extends StatelessWidget {
  const MenuHealthWarnings({super.key, required this.warnings});
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFFFF7D6), borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Check: ${warnings.join(' · ')}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// ★★★☆☆
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 16, this.onTap});
  final int rating;
  final double size;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            GestureDetector(
              onTap: onTap == null ? null : () => onTap!(i),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: onTap == null ? 0 : 4),
                child: Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: size,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Food profile
// ---------------------------------------------------------------------------

class ClientFoodProfileScreen extends ConsumerWidget {
  const ClientFoodProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clientFoodProfileProvider);
    return async.when(
      skipLoadingOnRefresh: true,
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => DsPage(
        title: 'Food profile',
        onBack: () => _backOrHome(context),
        body: dsAsyncBody(async, onRetry: () => ref.invalidate(clientFoodProfileProvider), builder: (_) => const []),
      ),
      data: (view) => _FoodProfileForm(key: ValueKey(view.profile?.version ?? 0), view: view),
    );
  }
}

class _FoodProfileForm extends ConsumerStatefulWidget {
  const _FoodProfileForm({super.key, required this.view});
  final ClientFoodProfileView view;

  @override
  ConsumerState<_FoodProfileForm> createState() => _FoodProfileFormState();
}

class _FoodProfileFormState extends ConsumerState<_FoodProfileForm> {
  late final FoodProfile _p = widget.view.profile?.copy() ?? FoodProfile();
  late final _allergies = TextEditingController(text: _p.allergies.join(', '));
  late final _cuisines = TextEditingController(text: _p.cuisines.join(', '));
  late final _otherHealth = TextEditingController(
    text: _p.healthConditions.where((h) => !CookEnums.healthConditions.contains(h)).map(carePretty).join(', '),
  );
  late final _dislikes = TextEditingController(text: _p.dislikes);
  late final _family = TextEditingController(text: _p.familySize?.toString());
  late final _notes = TextEditingController(text: _p.notes);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_allergies, _cuisines, _otherHealth, _dislikes, _family, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(FoodProfile profile, {String? success}) async {
    if (profile.dietType == null) {
      context.showDsSnackBar('Please choose the diet type.', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(careApiProvider).saveClientFoodProfile(profile);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      onSuccess: (view) {
        final changes = view.profile?.changes ?? const <String>[];
        context.showDsSnackBar(
          success ?? (changes.isEmpty ? 'Food profile saved' : 'Saved. ${changes.join(' · ')}'),
          type: DsSnackBarType.success,
        );
        ref.invalidate(clientFoodProfileProvider);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  void _save() {
    String? t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    _p
      ..allergies = careSplit(_allergies.text)
      ..cuisines = careSplit(_cuisines.text)
      ..healthConditions = [
        ..._p.healthConditions.where(CookEnums.healthConditions.contains),
        ...careSplit(_otherHealth.text),
      ]
      ..dislikes = t(_dislikes)
      ..familySize = int.tryParse(_family.text.trim())
      ..notes = t(_notes);
    _submit(_p);
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary)),
      );

  Widget _chips(List<String> values, bool Function(String) on, void Function(String) tap, {String Function(String)? label}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final v in values) DsChoiceChip(label: (label ?? carePretty)(v), selected: on(v), onTap: () => setState(() => tap(v)))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final saved = widget.view.profile;
    return DsPage(
      title: 'Food profile',
      subtitle: saved == null ? 'For your cook' : 'Version ${saved.version}',
      onBack: () => _backOrHome(context),
      bottom: DsGradientButton(label: 'Save', icon: Icons.save_rounded, isLoading: _saving, onPressed: _saving ? null : _save),
      body: [
        for (final s in widget.view.suggestions)
          if (saved != null && s.applyTo(saved) != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: dsCardDecoration(border: AppColors.warning),
              child: Row(
                children: [
                  const DsIconTile(Icons.lightbulb_rounded, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.suggestion, style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
                        Text(
                          '"${carePretty(s.tag)}" ${s.times} times in 2 weeks',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : () => _submit(s.applyTo(saved)!, success: 'Done — your cook has been told'),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ),
        const DsNote(text: 'This belongs to your home and stays the same if your cook changes. Your cook sees every change.'),
        const DsSection('Diet'),
        _chips(CookEnums.diets, (v) => _p.dietType == v, (v) => _p.dietType = v),
        _label('Spice level'),
        _chips(['1', '2', '3', '4', '5'], (v) => '${_p.spiceLevel}' == v, (v) => _p.spiceLevel = _p.spiceLevel == int.parse(v) ? null : int.parse(v),
            label: (v) => switch (v) { '1' => '1 Mild', '5' => '5 Very spicy', _ => v }),
        _label('Salt'),
        _chips(['LOW', 'NORMAL'], (v) => _p.salt == v, (v) => _p.salt = _p.salt == v ? null : v),
        _label('Oil'),
        _chips(['LOW', 'NORMAL'], (v) => _p.oil == v, (v) => _p.oil = _p.oil == v ? null : v),
        const DsSection('Health'),
        _chips(CookEnums.healthConditions, _p.healthConditions.contains,
            (v) => _p.healthConditions.contains(v) ? _p.healthConditions.remove(v) : _p.healthConditions.add(v)),
        DsLabeledField(label: 'Other health needs', controller: _otherHealth, icon: Icons.favorite_rounded, optional: true),
        const SizedBox(height: 12),
        DsLabeledField(
          label: 'Allergies',
          controller: _allergies,
          icon: Icons.warning_amber_rounded,
          hint: 'e.g. Peanuts, Shellfish (comma separated)',
          optional: true,
        ),
        const DsSection('Taste'),
        DsLabeledField(label: 'Cuisines', controller: _cuisines, icon: Icons.restaurant_menu_rounded, hint: 'e.g. North Indian, Gujarati', optional: true),
        const SizedBox(height: 12),
        DsLabeledField(label: 'Dislikes', controller: _dislikes, icon: Icons.thumb_down_alt_rounded, hint: 'e.g. Bitter gourd', optional: true),
        const SizedBox(height: 12),
        DsLabeledField(
          label: 'People to cook for',
          controller: _family,
          icon: Icons.groups_rounded,
          optional: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        DsLabeledField(label: 'Notes', controller: _notes, icon: Icons.edit_note_rounded, optional: true, maxLines: 3, textCapitalization: TextCapitalization.sentences),
        if (saved != null && saved.changes.isNotEmpty) ...[
          const DsSection('Last change'),
          for (final c in saved.changes)
            Text('• $c', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Week menu
// ---------------------------------------------------------------------------

class ClientMenuScreen extends ConsumerStatefulWidget {
  const ClientMenuScreen({super.key, required this.placementId, this.staffName});
  final String placementId;
  final String? staffName;

  @override
  ConsumerState<ClientMenuScreen> createState() => _ClientMenuScreenState();
}

class _ClientMenuScreenState extends ConsumerState<ClientMenuScreen> {
  late DateTime _weekStart = careWeekStart(careNowIst());

  ({String pid, String week}) get _key => (pid: widget.placementId, week: careYmd(_weekStart));

  Future<void> _editSlot(String date, String meal, MenuItem? current) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotSheet(date: date, meal: meal, current: current),
    );
    if (result == null || !mounted) return;
    final saved = await ref.read(careApiProvider).saveMenu(widget.placementId, [result]);
    if (!mounted) return;
    saved.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Menu saved — your cook has been told', type: DsSnackBarType.success);
        ref.invalidate(menuWeekProvider(_key));
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Future<void> _decide(MenuItem m, bool approve) async {
    String? reason;
    if (!approve) {
      reason = await careAskText(context, title: 'Decline this suggestion?', label: 'Reason', hint: 'Your cook will see this', confirmLabel: 'Decline');
      if (reason == null) return;
    }
    final api = ref.read(careApiProvider);
    final result = approve ? await api.approveMenu(m.id) : await api.rejectMenu(m.id, reason!);
    if (!mounted) return;
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar(approve ? 'Approved' : 'Declined', type: DsSnackBarType.success);
        ref.invalidate(menuWeekProvider(_key));
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(menuWeekProvider(_key));
    final today = careTodayIst();
    final thisWeek = careWeekStart(careNowIst());

    return DsPage(
      title: 'Week menu',
      subtitle: widget.staffName,
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(menuWeekProvider(_key)),
      actions: [
        DsPageAction(icon: Icons.restaurant_rounded, tooltip: 'Meals', onPressed: () => context.push(ClientRoutes.meals(widget.placementId))),
        DsPageAction(icon: Icons.tune_rounded, tooltip: 'Food profile', onPressed: () => context.push(ClientRoutes.foodProfile)),
      ],
      body: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous week',
              onPressed: _weekStart.isAfter(thisWeek) ? () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                _weekStart == thisWeek ? 'This week' : 'Week of ${_dayLabel(careYmd(_weekStart))}',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
              ),
            ),
            IconButton(
              tooltip: 'Next week',
              onPressed: () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        ...dsAsyncBody(
          async,
          onRetry: () => ref.invalidate(menuWeekProvider(_key)),
          builder: (week) => [
            for (var i = 0; i < 7; i++)
              _DayCard(
                date: careYmd(_weekStart.add(Duration(days: i))),
                week: week,
                editable: careYmd(_weekStart.add(Duration(days: i))).compareTo(today) >= 0,
                onEdit: _editSlot,
                onDecide: _decide,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.date, required this.week, required this.editable, required this.onEdit, required this.onDecide});
  final String date;
  final MenuWeek week;
  final bool editable;
  final void Function(String date, String meal, MenuItem? current) onEdit;
  final void Function(MenuItem m, bool approve) onDecide;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        decoration: dsCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              date == careTodayIst() ? 'Today · ${_dayLabel(date)}' : _dayLabel(date),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: editable ? AppColors.lightTextPrimary : AppColors.lightTextSecondary,
              ),
            ),
            for (final meal in CookEnums.meals) _slot(context, meal, week.slot(date, meal)),
          ],
        ),
      );

  Widget _slot(BuildContext context, String meal, MenuItem? m) {
    final look = m == null ? null : _menuStatusLook(m);
    return InkWell(
      onTap: editable ? () => onEdit(date, meal, m) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 82,
                  child: Text(carePretty(meal), style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m == null ? (editable ? 'Tap to set' : '—') : m.dishText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: m == null ? FontWeight.w500 : FontWeight.w700,
                          color: m == null ? AppColors.lightTextSecondary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (m?.specialInstruction != null)
                        Text('Note: ${m!.specialInstruction}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary)),
                      if (m?.rejectReason != null && m!.status == MenuStatus.rejected)
                        Text('You declined: ${m.rejectReason}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.error)),
                    ],
                  ),
                ),
                if (look != null) DsPill(look.$1, color: look.$2),
              ],
            ),
            if (m != null) MenuHealthWarnings(warnings: m.healthWarnings),
            if (m != null && m.awaitingApproval && editable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(child: DsOutlineButton(label: 'Decline', onPressed: () => onDecide(m, false))),
                    const SizedBox(width: 10),
                    Expanded(child: DsGradientButton(label: 'Approve', icon: Icons.check_rounded, onPressed: () => onDecide(m, true))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sets one slot: dishes (one per line), a note for the cook, servings.
class _SlotSheet extends StatefulWidget {
  const _SlotSheet({required this.date, required this.meal, this.current});
  final String date;
  final String meal;
  final MenuItem? current;

  @override
  State<_SlotSheet> createState() => _SlotSheetState();
}

class _SlotSheetState extends State<_SlotSheet> {
  late final _dishes = TextEditingController(text: widget.current?.dishes.map((d) => d.name).join('\n'));
  late final _note = TextEditingController(text: widget.current?.specialInstruction);
  late final _servings = TextEditingController(text: widget.current?.servings?.toString());

  @override
  void dispose() {
    _dishes.dispose();
    _note.dispose();
    _servings.dispose();
    super.dispose();
  }

  Map<String, dynamic> _item(List<String> dishes) => {
        'date': widget.date,
        'meal': widget.meal,
        'dishes': dishes,
        if (dishes.isNotEmpty && _note.text.trim().isNotEmpty) 'special_instruction': _note.text.trim(),
        if (dishes.isNotEmpty && int.tryParse(_servings.text.trim()) != null) 'servings': int.parse(_servings.text.trim()),
      };

  @override
  Widget build(BuildContext context) {
    final dishes = [for (final l in _dishes.text.split('\n')) if (l.trim().isNotEmpty) l.trim()];
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
                Text(
                  '${carePretty(widget.meal)} · ${_dayLabel(widget.date)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                ),
                if (widget.current?.awaitingApproval ?? false) ...[
                  const SizedBox(height: 8),
                  const DsNote(text: 'Saving your own dishes replaces the cook\'s suggestion.'),
                ],
                const SizedBox(height: 14),
                DsLabeledField(
                  label: 'Dishes (one per line)',
                  controller: _dishes,
                  icon: Icons.restaurant_rounded,
                  hint: 'Dal\nRoti\nBhindi',
                  maxLines: 6,
                  minLines: 3,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DsLabeledField(label: 'Note for the cook', controller: _note, icon: Icons.edit_note_rounded, hint: 'e.g. Less spicy', optional: true),
                const SizedBox(height: 12),
                DsLabeledField(
                  label: 'Servings',
                  controller: _servings,
                  icon: Icons.groups_rounded,
                  optional: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                DsGradientButton(
                  label: 'Save',
                  icon: Icons.check_rounded,
                  onPressed: dishes.isEmpty ? null : () => Navigator.of(context).pop(_item(dishes)),
                ),
                if (widget.current != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_item(const [])),
                    child: Text('Clear this meal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.error)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meals feed + rating
// ---------------------------------------------------------------------------

class ClientMealsScreen extends ConsumerWidget {
  const ClientMealsScreen({super.key, required this.placementId});
  final String placementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (pid: placementId, days: 14);
    final async = ref.watch(mealsProvider(key));

    Future<void> rate(MealLog m) async {
      final result = await showModalBottomSheet<({int rating, List<String> tags, String? comment})>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RateSheet(meal: m),
      );
      if (result == null || !context.mounted) return;
      final r = await ref.read(careApiProvider).rateMeal(m.id, rating: result.rating, tags: result.tags, comment: result.comment);
      if (!context.mounted) return;
      r.fold(
        onSuccess: (_) {
          context.showDsSnackBar('Thanks — your cook will see this', type: DsSnackBarType.success);
          ref.invalidate(mealsProvider(key));
          ref.invalidate(clientFoodProfileProvider);
        },
        onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
      );
    }

    return DsPage(
      title: 'Meals',
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(mealsProvider(key)),
      body: dsAsyncBody(
        async,
        onRetry: () => ref.invalidate(mealsProvider(key)),
        builder: (v) => [
          if (v.rating.count30d > 0)
            DsListCard(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: v.rating.avg7d != null ? '${v.rating.avg7d} / 5 this week' : '${v.rating.avg30d} / 5 this month',
              subtitle: '${v.rating.count7d} ratings in 7 days · ${v.rating.count30d} in 30 days',
            ),
          if (v.items.isEmpty)
            const DsEmptyBlock(
              icon: Icons.restaurant_rounded,
              title: 'No meals logged yet',
              message: 'When your cook logs a meal, it shows here with photos so you can rate it.',
            )
          else
            for (final m in v.items) _MealCard(meal: m, onRate: () => rate(m)),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.onRate});
  final MealLog meal;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final m = meal;
    final f = m.feedback;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DsIconTile(Icons.restaurant_rounded, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${carePretty(m.meal)} · ${_dayLabel(m.date)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                ),
              ),
              if (f != null) StarRow(rating: f.rating),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            m.dishes.map((d) => d.spiceLevel == null ? d.name : '${d.name} (spice ${d.spiceLevel})').join(', '),
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.lightTextPrimary),
          ),
          if (m.notes != null)
            Text(m.notes!, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.lightTextSecondary)),
          if (m.photoFileIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            CarePhotoStrip(fileIds: m.photoFileIds),
          ],
          if (f != null && (f.tags.isNotEmpty || f.comment != null)) ...[
            const SizedBox(height: 8),
            Text(
              [...f.tags.map(carePretty), if (f.comment != null) '"${f.comment}"'].join(' · '),
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRate,
              icon: const Icon(Icons.star_outline_rounded),
              label: Text(f == null ? 'Rate' : 'Change rating'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateSheet extends StatefulWidget {
  const _RateSheet({required this.meal});
  final MealLog meal;

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  late int _rating = widget.meal.feedback?.rating ?? 0;
  late final Set<String> _tags = {...?widget.meal.feedback?.tags};
  late final _comment = TextEditingController(text: widget.meal.feedback?.comment);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'How was ${carePretty(widget.meal.meal).toLowerCase()}?',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                ),
                const SizedBox(height: 12),
                Center(child: StarRow(rating: _rating, size: 38, onTap: (r) => setState(() => _rating = r))),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in CookEnums.feedbackTags)
                      DsChoiceChip(
                        label: carePretty(t),
                        selected: _tags.contains(t),
                        onTap: () => setState(() => _tags.contains(t) ? _tags.remove(t) : _tags.add(t)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                DsLabeledField(label: 'Comment', controller: _comment, optional: true, textCapitalization: TextCapitalization.sentences),
                const SizedBox(height: 16),
                DsGradientButton(
                  label: 'Send rating',
                  onPressed: _rating == 0
                      ? null
                      : () => Navigator.of(context).pop((
                            rating: _rating,
                            tags: [for (final t in CookEnums.feedbackTags) if (_tags.contains(t)) t],
                            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
                          )),
                ),
              ],
            ),
          ),
        ),
      );
}
