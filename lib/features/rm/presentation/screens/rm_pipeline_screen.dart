import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/async_value_widget.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

class RmPipelineScreen extends ConsumerStatefulWidget {
  const RmPipelineScreen({super.key});

  @override
  ConsumerState<RmPipelineScreen> createState() => _RmPipelineScreenState();
}

class _RmPipelineScreenState extends ConsumerState<RmPipelineScreen> {
  String? _seriesFilter;
  String _search = '';
  Timer? _debounce;
  final _searchController = TextEditingController();

  static const _filters = <String, String?>{
    'All Series': null,
    'Driver': StaffSeries.driver,
    'Skilled Care': StaffSeries.skilledCare,
    'Unskilled Care': StaffSeries.unskilledCare,
    'Maid': StaffSeries.maid,
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _search = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = KanbanParams(search: _search.isEmpty ? null : _search, series: _seriesFilter);
    final kanban = ref.watch(rmKanbanProvider(params));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          const Divider(height: 1, color: RmTheme.borderSubtle),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(rmKanbanProvider(params)),
              child: AsyncValueWidget<KanbanResult>(
                value: kanban,
                onRetry: () => ref.invalidate(rmKanbanProvider(params)),
                errorTitle: 'Could not load pipeline',
                builder: (data) => _buildKanbanBoard(context, data),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RmRoutes.staffIntake),
        backgroundColor: RmTheme.electricBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 1),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: RmTheme.cardSurface,
      elevation: 0,
      title: Text('Pipeline', style: RmTheme.headline(context).copyWith(fontSize: 20)),
      actions: [
        IconButton(
          tooltip: 'Trials',
          icon: const Icon(Icons.play_circle_outline, color: RmTheme.textPrimary),
          onPressed: () => context.push(RmRoutes.trials),
        ),
        IconButton(
          tooltip: 'Deferred',
          icon: const Icon(Icons.pause_circle_outline, color: RmTheme.textPrimary),
          onPressed: () => context.push(RmRoutes.deferred),
        ),
        IconButton(
          tooltip: 'Terminal',
          icon: const Icon(Icons.block, color: RmTheme.textPrimary),
          onPressed: () => context.push(RmRoutes.terminal),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: RmTheme.cardSurface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by name or staff code',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          filled: true,
          fillColor: RmTheme.offWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: RmTheme.cardSurface,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.entries.map((entry) {
            final isActive = _seriesFilter == entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.key, style: RmTheme.label(context).copyWith(color: isActive ? Colors.white : RmTheme.textSecondary)),
                selected: isActive,
                onSelected: (selected) {
                  if (selected) setState(() => _seriesFilter = entry.value);
                },
                selectedColor: RmTheme.electricBlue,
                backgroundColor: RmTheme.offWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isActive ? RmTheme.electricBlue : RmTheme.borderSubtle),
                ),
                showCheckmark: isActive,
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKanbanBoard(BuildContext context, KanbanResult data) {
    if (data.total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No staff match this filter yet.'),
        ),
      );
    }
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      children: [
        for (final stage in PipelineStages.order)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildKanbanColumn(context, stage, data.columns[stage] ?? const []),
          ),
      ],
    );
  }

  Widget _buildKanbanColumn(BuildContext context, String stage, List<StaffRow> items) {
    return Container(
      width: 300,
      decoration: BoxDecoration(color: RmTheme.offWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: RmTheme.textSecondary, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(PipelineStages.label(stage), style: RmTheme.label(context).copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: RmTheme.borderSubtle, borderRadius: BorderRadius.circular(12)),
                  child: Text(items.length.toString(), style: RmTheme.label(context).copyWith(fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Empty', style: TextStyle(color: RmTheme.textSecondary))),
                  )
                : ListView(children: [for (final staff in items) _buildStaffCard(context, staff)]),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context, StaffRow staff) {
    return GestureDetector(
      onTap: () => context.push(RmRoutes.staffDetail(staff.id), extra: staff),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: RmTheme.cardSurface, borderRadius: BorderRadius.circular(12), boxShadow: RmTheme.sophisticatedShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: RmTheme.borderSubtle, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Text(staff.initials, style: RmTheme.title(context).copyWith(color: RmTheme.textSecondary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.fullName, style: RmTheme.label(context).copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(staff.staffCode, style: RmTheme.body(context).copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: RmTheme.electricBlueLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: RmTheme.electricBlueLight.withOpacity(0.3)),
                  ),
                  child: Text(staff.series, style: RmTheme.label(context).copyWith(color: RmTheme.electricBlueLight, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if (staff.pvStatus != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: RmTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('PV: ${staff.pvStatus}', style: RmTheme.label(context).copyWith(fontSize: 11, color: RmTheme.textSecondary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
