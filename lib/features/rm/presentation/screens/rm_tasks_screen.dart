import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../widgets/rm_bottom_navigation.dart';

class RmTasksScreen extends ConsumerStatefulWidget {
  const RmTasksScreen({super.key});

  @override
  ConsumerState<RmTasksScreen> createState() => _RmTasksScreenState();
}

class _RmTasksScreenState extends ConsumerState<RmTasksScreen> {
  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Review Video Certification',
      'subtitle': 'Hunesh S. (Maid) - Stage 3',
      'isCompleted': false,
      'isUrgent': true,
      'time': 'Due Today',
    },
    {
      'title': 'Approve SOW Agreement',
      'subtitle': 'Sharma Household (Bandra West)',
      'isCompleted': false,
      'isUrgent': true,
      'time': 'Due Today',
    },
    {
      'title': 'Check-in Call: Trial Period',
      'subtitle': 'Priya K. (Caretaker) - Day 3',
      'isCompleted': true,
      'isUrgent': false,
      'time': 'Completed',
    },
    {
      'title': 'Verify Medical Documents',
      'subtitle': 'Arun J. (Driver)',
      'isCompleted': false,
      'isUrgent': false,
      'time': 'Tomorrow',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        title: Text('My Tasks', style: RmTheme.headline(context).copyWith(fontSize: 20)),
        backgroundColor: RmTheme.cardSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: RmTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return _buildTaskCard(task, index);
        },
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    final isCompleted = task['isCompleted'] as bool;
    final isUrgent = task['isUrgent'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent && !isCompleted ? RmTheme.crimsonDanger.withOpacity(0.3) : RmTheme.borderSubtle,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _tasks[index]['isCompleted'] = !isCompleted;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? RmTheme.emeraldGreen : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? RmTheme.emeraldGreen : RmTheme.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isCompleted ? RmTheme.textSecondary : RmTheme.textPrimary,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task['subtitle'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: RmTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isUrgent && !isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: RmTheme.crimsonDanger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Urgent',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: RmTheme.crimsonDanger,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      task['time'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isCompleted ? RmTheme.emeraldGreen : RmTheme.textSecondary,
                        fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
