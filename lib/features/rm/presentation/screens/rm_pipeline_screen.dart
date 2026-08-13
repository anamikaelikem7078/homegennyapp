import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../../../../common/domain/models/staff_entity.dart';
import '../widgets/rm_bottom_navigation.dart';

class RmPipelineScreen extends ConsumerStatefulWidget {
  const RmPipelineScreen({super.key});

  @override
  ConsumerState<RmPipelineScreen> createState() => _RmPipelineScreenState();
}

class _RmPipelineScreenState extends ConsumerState<RmPipelineScreen> {
  String _activeFilter = 'All Roles';
  final List<String> _filters = ['All Roles', 'Driver', 'Caretaker', 'Maid'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(height: 1, color: RmTheme.borderSubtle),
          Expanded(
            child: _buildKanbanBoard(context),
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
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: const CircleAvatar(
          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150'),
        ),
      ),
      title: Text('Command Center', style: RmTheme.headline(context).copyWith(fontSize: 20)),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: RmTheme.textPrimary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: RmTheme.cardSurface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((filter) {
            final isActive = _activeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: RmTheme.label(context).copyWith(
                    color: isActive ? Colors.white : RmTheme.textSecondary,
                  ),
                ),
                selected: isActive,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _activeFilter = filter);
                  }
                },
                selectedColor: RmTheme.electricBlue,
                backgroundColor: RmTheme.offWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isActive ? RmTheme.electricBlue : RmTheme.borderSubtle,
                  ),
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

  Widget _buildKanbanBoard(BuildContext context) {
    final pipeline = ref.watch(rmPipelineProvider);

    bool matchFilter(StaffEntity staff) {
      if (_activeFilter == 'All Roles') return true;
      // In a real app we'd map roles properly; here we simplify based on prefix or property if available
      final roleHint = staff.staffCode.contains('-DR-') ? 'Driver' : (staff.staffCode.contains('-MA-') ? 'Maid' : 'Caretaker');
      return roleHint.toLowerCase() == _activeFilter.toLowerCase();
    }

    final s1Items = (pipeline['REGISTRATION'] ?? []).where(matchFilter).toList();
    final s2Items = (pipeline['VERIFICATION'] ?? []).where(matchFilter).toList();
    final s3Items = (pipeline['TRAINING'] ?? []).where(matchFilter).toList();
    final s4Items = (pipeline['VIDEO_CERTIFICATION'] ?? []).where(matchFilter).toList();

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      children: [
        _buildKanbanColumn(
          context,
          'S1 Intake',
          s1Items.length,
          s1Items.map((item) => _buildStaffCard(context, item.name, item.id, 'STAFF', 20.0, 'In Progress', item.profileImage)).toList(),
        ),
        const SizedBox(width: 16),
        _buildKanbanColumn(
          context,
          'S2 Verification',
          s2Items.length,
          s2Items.map((item) => _buildStaffCard(context, item.name, item.id, 'STAFF', 45.0, 'Pending docs', item.profileImage)).toList(),
        ),
        const SizedBox(width: 16),
        _buildKanbanColumn(
          context,
          'S3 Training',
          s3Items.length,
          s3Items.map((item) => _buildStaffCard(context, item.name, item.id, 'STAFF', 60.0, 'In progress', item.profileImage)).toList(),
        ),
        const SizedBox(width: 16),
        _buildKanbanColumn(
          context,
          'S4 Video & More',
          s4Items.length,
          s4Items.map((item) => _buildStaffCard(context, item.name, item.id, 'STAFF', 80.0, 'Pending video', item.profileImage)).toList(),
        ),
      ],
    );
  }

  Widget _buildKanbanColumn(BuildContext context, String title, int count, List<Widget> cards) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: RmTheme.offWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: RmTheme.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(title, style: RmTheme.label(context).copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: RmTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(count.toString(), style: RmTheme.label(context).copyWith(fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: cards,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context, String name, String id, String role, double progress, String pending, String? imageUrl) {
    Color roleColor;
    if (role == 'DRIVER') {
      roleColor = RmTheme.electricBlueLight;
    } else if (role == 'MAID') {
      roleColor = RmTheme.emeraldGreen;
    } else {
      roleColor = RmTheme.amberWarning;
    }

    return GestureDetector(
      onTap: () => context.push(RmRoutes.staffDetail(id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RmTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: RmTheme.sophisticatedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: RmTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.substring(0, 2).toUpperCase(),
                      style: RmTheme.title(context).copyWith(color: RmTheme.textSecondary),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: RmTheme.label(context).copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(id, style: RmTheme.body(context).copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    role,
                    style: RmTheme.label(context).copyWith(color: roleColor, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Intake Progress', style: RmTheme.body(context).copyWith(fontSize: 12)),
                Text('${progress.toInt()}%', style: RmTheme.label(context).copyWith(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: RmTheme.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(RmTheme.textSecondary),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: RmTheme.amberWarning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions, size: 14, color: RmTheme.amberWarning),
                      const SizedBox(width: 4),
                      Text(pending, style: RmTheme.label(context).copyWith(color: RmTheme.amberWarning, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: RmTheme.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
