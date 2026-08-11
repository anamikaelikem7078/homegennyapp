import 'package:flutter/material.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
import '../navigation/rm_routes.dart';

class RmPipelineScreen extends StatefulWidget {
  const RmPipelineScreen({super.key});

  @override
  State<RmPipelineScreen> createState() => _RmPipelineScreenState();
}

class _RmPipelineScreenState extends State<RmPipelineScreen> {
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
      bottomNavigationBar: _buildBottomNav(context),
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
    final s1Items = [
      {'name': 'Ramesh K.', 'id': 'DR-147', 'role': 'DRIVER', 'progress': 20.0, 'pending': '3 Pending', 'imageUrl': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150'},
      {'name': 'Sarah J.', 'id': 'MA-092', 'role': 'MAID', 'progress': 10.0, 'pending': '5 Pending', 'imageUrl': null},
    ];

    final s2Items = [
      {'name': 'Priya M.', 'id': 'CA-044', 'role': 'CARETAKER', 'progress': 45.0, 'pending': '2 Pending', 'imageUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150'},
    ];

    bool matchFilter(String role) {
      if (_activeFilter == 'All Roles') return true;
      return role.toLowerCase() == _activeFilter.toLowerCase();
    }

    final filteredS1 = s1Items.where((item) => matchFilter(item['role'] as String)).toList();
    final filteredS2 = s2Items.where((item) => matchFilter(item['role'] as String)).toList();

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      children: [
        _buildKanbanColumn(
          context,
          'S1 Intake',
          filteredS1.length,
          filteredS1.map((item) => _buildStaffCard(context, item['name'] as String, item['id'] as String, item['role'] as String, item['progress'] as double, item['pending'] as String, item['imageUrl'] as String?)).toList(),
        ),
        const SizedBox(width: 16),
        _buildKanbanColumn(
          context,
          'S2 Verification',
          filteredS2.length,
          filteredS2.map((item) => _buildStaffCard(context, item['name'] as String, item['id'] as String, item['role'] as String, item['progress'] as double, item['pending'] as String, item['imageUrl'] as String?)).toList(),
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

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard_outlined, 'Dashboard', false, onTap: () => context.pushReplacement(RmRoutes.dashboard)),
              _buildNavItem(Icons.view_kanban, 'Pipeline', true),
              _buildNavItem(Icons.check_circle_outline, 'Tasks', false),
              _buildNavItem(Icons.notifications_outlined, 'Alerts', false),
              _buildNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: RmTheme.electricBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? RmTheme.electricBlue : RmTheme.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: RmTheme.label(context).copyWith(
                color: isActive ? RmTheme.electricBlue : RmTheme.textSecondary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
