import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/design_system.dart';
import '../../../care/data/care_api.dart';
import '../../../care/domain/cook_models.dart';
import '../../../care/presentation/care_widgets.dart';

/// A dish chosen in a [DishPicker]. [id] is null for a typed name.
class PickedDish {
  const PickedDish({required this.name, this.id});
  final String? id;
  final String name;

  @override
  bool operator ==(Object other) => other is PickedDish && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Splits picked dishes into the request body's `dish_ids` and `dishes`.
({List<String> ids, List<String> typed}) splitPickedDishes(List<PickedDish> dishes) => (
      ids: [for (final d in dishes) if (d.id != null) d.id!],
      typed: [for (final d in dishes) if (d.id == null) d.name],
    );

/// The chosen dishes as chips plus "Add a dish", which opens the searchable
/// dish dropdown (`GET /care/dishes`) with "+ Add '…' as my dish".
class DishPicker extends StatelessWidget {
  const DishPicker({
    super.key,
    required this.dishes,
    required this.onChanged,
    this.meal,
    this.maxDishes,
  });

  final List<PickedDish> dishes;
  final ValueChanged<List<PickedDish>> onChanged;

  /// Sent as `meal` so dishes for that meal come first.
  final String? meal;

  /// Stops adding at this many dishes; null = no cap.
  final int? maxDishes;

  bool get _full => maxDishes != null && dishes.length >= maxDishes!;

  Future<void> _add(BuildContext context) async {
    final picked = await showModalBottomSheet<PickedDish>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DishSearchSheet(meal: meal),
    );
    if (picked == null || dishes.contains(picked)) return;
    onChanged([...dishes, picked]);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in dishes)
                InputChip(
                  label: Text(d.name),
                  onDeleted: () => onChanged([...dishes]..remove(d)),
                ),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18),
                label: Text(_full ? 'No more dishes fit' : 'Add a dish'),
                onPressed: _full ? null : () => _add(context),
              ),
            ],
          ),
        ],
      );
}

class _DishSearchSheet extends ConsumerStatefulWidget {
  const _DishSearchSheet({this.meal});
  final String? meal;

  @override
  ConsumerState<_DishSearchSheet> createState() => _DishSearchSheetState();
}

class _DishSearchSheetState extends ConsumerState<_DishSearchSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  DishSearch? _result;
  String? _error;
  bool _loading = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onTyped(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final seq = ++_seq;
    setState(() => _loading = true);
    final result = await ref.read(careApiProvider).searchDishes(q: _query.text, meal: widget.meal, limit: 30);
    // A slower, older search must not overwrite a newer one.
    if (!mounted || seq != _seq) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final r):
          _result = r;
          _error = null;
        case Error(failure: final f):
          _error = f.message;
      }
    });
  }

  Future<void> _addOwn() async {
    final name = _query.text.trim();
    final dish = await showModalBottomSheet<Dish>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddOwnDishSheet(name: name, meal: widget.meal),
    );
    if (dish != null && mounted) Navigator.of(context).pop(PickedDish(id: dish.id, name: dish.name));
  }

  @override
  Widget build(BuildContext context) {
    final typed = _query.text.trim();
    final items = _result?.items ?? const <Dish>[];
    return _SheetFrame(
      title: widget.meal == null ? 'Add a dish' : 'Add a dish · ${carePretty(widget.meal!)}',
      children: [
        DsLabeledField(
          label: 'Search dishes',
          controller: _query,
          icon: Icons.search_rounded,
          hint: 'e.g. Dal makhani',
          textCapitalization: TextCapitalization.words,
          onChanged: _onTyped,
        ),
        const SizedBox(height: 12),
        if (_loading && _result == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          DsNote(tone: DsNoteTone.danger, text: _error!)
        else ...[
          if (items.isEmpty) const DsNote(text: 'No dishes match.'),
          for (final d in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                d.own ? Icons.person_rounded : Icons.restaurant_rounded,
                color: d.diet == 'NON_VEG' ? AppColors.error : AppColors.success,
              ),
              title: Text(d.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              subtitle: Text(
                [if (d.category != null) Dish.categories[d.category] ?? carePretty(d.category!), if (d.own) 'My dish']
                    .join(' · '),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
              ),
              onTap: () => Navigator.of(context).pop(PickedDish(id: d.id, name: d.name)),
            ),
          if ((_result?.canAdd ?? false) && typed.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              title: Text(
                "+ Add '$typed' as my dish",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              onTap: _addOwn,
            ),
        ],
      ],
    );
  }
}

/// "Add as my dish": category + diet, then `POST /client/dishes`.
class _AddOwnDishSheet extends ConsumerStatefulWidget {
  const _AddOwnDishSheet({required this.name, this.meal});
  final String name;
  final String? meal;

  @override
  ConsumerState<_AddOwnDishSheet> createState() => _AddOwnDishSheetState();
}

class _AddOwnDishSheetState extends ConsumerState<_AddOwnDishSheet> {
  String? _category;
  String _diet = 'VEG';
  bool _saving = false;

  Future<void> _save() async {
    if (_category == null) {
      context.showDsSnackBar('Please choose a category.', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(careApiProvider).addOwnDish(
          name: widget.name,
          category: _category!,
          diet: _diet,
          meals: [?widget.meal],
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      onSuccess: (dish) => Navigator.of(context).pop(dish),
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
        ),
      );

  @override
  Widget build(BuildContext context) => _SheetFrame(
        title: "Add '${widget.name}'",
        children: [
          _label('Category'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in Dish.categories.entries)
                DsChoiceChip(label: e.value, selected: _category == e.key, onTap: () => setState(() => _category = e.key)),
            ],
          ),
          const SizedBox(height: 14),
          _label('Diet'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in Dish.diets)
                DsChoiceChip(label: carePretty(d), selected: _diet == d, onTap: () => setState(() => _diet = d)),
            ],
          ),
          const SizedBox(height: 18),
          DsGradientButton(
            label: 'Add as my dish',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                ),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      );
}
