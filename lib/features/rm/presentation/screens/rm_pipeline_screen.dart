import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

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

  Color _stageColor(String stage) => switch (stage) {
        PipelineStages.s1Intake => const Color(0xFF6366F1), // Indigo
        PipelineStages.s2Verify => const Color(0xFF0D9488), // Teal
        PipelineStages.s25Assess => const Color(0xFFD97706), // Amber
        PipelineStages.s3Train => const Color(0xFF8B5CF6), // Purple
        PipelineStages.s4Agreements => const Color(0xFF1A56FF), // Electric Blue
        PipelineStages.s5Deploy => const Color(0xFF10B981), // Emerald
        _ => RmTheme.textSecondary,
      };

  Color _seriesColor(String series) => switch (series.toUpperCase()) {
        'DR' => const Color(0xFF3B82F6),
        'SC' => const Color(0xFF8B5CF6),
        'UC' => const Color(0xFFF97316),
        'MAID' => const Color(0xFF06B6D4),
        _ => RmTheme.electricBlue,
      };

  Color _pvColor(String? status) => switch (status) {
        'CLEAR' => RmTheme.emeraldGreen,
        'IN_PROGRESS' => RmTheme.amberWarning,
        'ADVERSE' || 'EXPIRED' => RmTheme.crimsonDanger,
        _ => RmTheme.textSecondary,
      };

  Color _avatarBgColor(String initials) {
    if (initials.isEmpty || initials == '?') return RmTheme.surfaceSecondary;
    final code = initials.codeUnitAt(0);
    final colors = [
      const Color(0xFFEFF6FF), // soft blue
      const Color(0xFFF0FDF4), // soft green
      const Color(0xFFFEF2F2), // soft red
      const Color(0xFFFFF7ED), // soft orange
      const Color(0xFFFAF5FF), // soft purple
      const Color(0xFFEDFDFD), // soft cyan
    ];
    return colors[code % colors.length];
  }

  Color _avatarTextColor(String initials) {
    if (initials.isEmpty || initials == '?') return RmTheme.textSecondary;
    final code = initials.codeUnitAt(0);
    final colors = [
      const Color(0xFF1E40AF), // blue
      const Color(0xFF166534), // green
      const Color(0xFF991B1B), // red
      const Color(0xFF9A3412), // orange
      const Color(0xFF6B21A8), // purple
      const Color(0xFF155E75), // cyan
    ];
    return colors[code % colors.length];
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
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 1),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: RmTheme.cardSurface,
      elevation: 0,
      title: Row(
        children: [
          Text('Pipeline', style: RmTheme.headline(context).copyWith(fontSize: 22)),
        ],
      ),
      actions: [
        _buildHeaderAction(
          context,
          icon: Icons.play_arrow_rounded,
          tooltip: 'Trials',
          color: RmTheme.emeraldGreen,
          onPressed: () => context.push(RmRoutes.trials),
        ),
        _buildHeaderAction(
          context,
          icon: Icons.pause_rounded,
          tooltip: 'Deferred',
          color: RmTheme.amberWarning,
          onPressed: () => context.push(RmRoutes.deferred),
        ),
        _buildHeaderAction(
          context,
          icon: Icons.block_rounded,
          tooltip: 'Terminal',
          color: RmTheme.crimsonDanger,
          onPressed: () => context.push(RmRoutes.terminal),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderAction(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: RmTheme.cardSurface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: RmTheme.body(context).copyWith(color: RmTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by name or staff code',
          hintStyle: RmTheme.body(context).copyWith(color: RmTheme.textSecondary.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: RmTheme.electricBlue),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: RmTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: RmTheme.surfaceSecondary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: RmTheme.electricBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: RmTheme.cardSurface,
      padding: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.entries.map((entry) {
            final isActive = _seriesFilter == entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _seriesFilter = entry.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? RmTheme.electricBlue : RmTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: RmTheme.electricBlue.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ] : null,
                    border: Border.all(
                      color: isActive ? RmTheme.electricBlue : RmTheme.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive) ...[
                        const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        entry.key,
                        style: RmTheme.label(context).copyWith(
                          color: isActive ? Colors.white : RmTheme.textSecondary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKanbanBoard(BuildContext context, KanbanResult data) {
    if (data.total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 48, color: RmTheme.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'No staff match this filter yet.',
                style: RmTheme.body(context).copyWith(color: RmTheme.textSecondary),
              ),
            ],
          ),
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
    final themeColor = _stageColor(stage);
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RmTheme.borderSubtle, width: 1),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: RmTheme.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  PipelineStages.label(stage),
                  style: RmTheme.label(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    items.length.toString(),
                    style: RmTheme.label(context).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 32,
                            color: RmTheme.textSecondary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Empty Stage',
                            style: RmTheme.body(context).copyWith(
                              fontSize: 12,
                              color: RmTheme.textSecondary.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildStaffCard(context, items[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context, StaffRow staff) {
    final themeColor = _stageColor(staff.pipelineStage);
    final avatarBg = _avatarBgColor(staff.initials);
    final avatarText = _avatarTextColor(staff.initials);
    final seriesColor = _seriesColor(staff.series);

    return GestureDetector(
      onTap: () => context.push(RmRoutes.staffDetail(staff.id), extra: staff),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: RmTheme.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RmTheme.borderSubtle, width: 1),
          boxShadow: RmTheme.subtleShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: themeColor, width: 4),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: avatarBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        staff.initials,
                        style: GoogleFonts.inter(
                          color: avatarText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.fullName,
                            style: RmTheme.label(context).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: RmTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            staff.staffCode,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: RmTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: seriesColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        staff.series,
                        style: RmTheme.label(context).copyWith(
                          color: seriesColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (staff.pvStatus != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: RmTheme.borderSubtle),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 13,
                            color: _pvColor(staff.pvStatus),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Verification: ',
                            style: RmTheme.body(context).copyWith(
                              fontSize: 10.5,
                              color: RmTheme.textSecondary,
                            ),
                          ),
                          Text(
                            staff.pvStatus!,
                            style: RmTheme.label(context).copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _pvColor(staff.pvStatus),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: RmTheme.textSecondary.withOpacity(0.5),
                      ),
                    ],
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
