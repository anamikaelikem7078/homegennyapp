import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

/// Incidents — repurposed from the former "Alerts" tab, which had no
/// backend equivalent (hardcoded mock notification list). Incidents
/// (`GET`/`POST /rm/incidents`) is a real, required RM module needing a
/// home; this reuses the existing bottom-nav slot.
class RmAlertsScreen extends ConsumerWidget {
  const RmAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(rmIncidentsProvider(null));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        title: Text(
          'Incidents',
          style: RmTheme.headline(context).copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: RmTheme.textPrimary, size: 24),
            onPressed: () => _showCreateSheet(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: RmTheme.electricBlue,
        onRefresh: () async => ref.invalidate(rmIncidentsProvider(null)),
        child: AsyncValueWidget<List<IncidentRow>>(
          value: incidentsAsync,
          onRetry: () => ref.invalidate(rmIncidentsProvider(null)),
          builder: (incidents) {
            if (incidents.isEmpty) {
              return Center(
                child: Text(
                  'No incidents on file.',
                  style: GoogleFonts.inter(
                    color: RmTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final i = incidents[index];
                final displayType = IncidentTypes.label(i.type).toUpperCase();
                final hasStaff = i.staff != null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: RmTheme.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x02000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: RmTheme.crimsonDanger.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(i.type),
                          color: RmTheme.crimsonDanger,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        i.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$displayType${hasStaff ? " • ${i.staff!.fullName}" : ""}\nStatus: ${i.status.toUpperCase()}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: RmTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                      isThreeLine: hasStaff,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 50 * index),
                      duration: 400.ms,
                    )
                    .slideY(
                      begin: 0.04,
                      end: 0,
                      delay: Duration(milliseconds: 50 * index),
                      duration: 400.ms,
                    );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 3),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        IncidentTypes.clientComplaint => Icons.sentiment_dissatisfied_outlined,
        IncidentTypes.staffMisconduct => Icons.person_off_outlined,
        IncidentTypes.safetyIssue => Icons.warning_amber_rounded,
        IncidentTypes.attendanceFraud => Icons.gpp_bad_outlined,
        IncidentTypes.drivingViolation => Icons.car_crash_outlined,
        IncidentTypes.lateExit => Icons.exit_to_app_rounded,
        _ => Icons.report_problem_outlined,
      };

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CreateIncidentSheet(ref: ref),
    );
  }
}

class _CreateIncidentSheet extends StatefulWidget {
  const _CreateIncidentSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_CreateIncidentSheet> createState() => _CreateIncidentSheetState();
}

class _CreateIncidentSheetState extends State<_CreateIncidentSheet> {
  String _type = IncidentTypes.clientComplaint;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _staffIdController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _staffIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await widget.ref.read(rmRepositoryProvider).createIncident({
      'type': _type,
      'title': _titleController.text.trim(),
      if (_descController.text.trim().isNotEmpty) 'description': _descController.text.trim(),
      if (_staffIdController.text.trim().isNotEmpty) 'staff_id': _staffIdController.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      onSuccess: (_) {
        widget.ref.invalidate(rmIncidentsProvider(null));
        widget.ref.invalidate(rmDashboardProvider);
        Navigator.of(context).pop();
      },
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: RmTheme.crimsonDanger,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RmTheme.offWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sheet Drag Handle Line ──
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: RmTheme.borderSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // ── Header Title ──
          Text(
            'New Incident',
            style: GoogleFonts.libreCaslonText(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 18),

          // ── Dropdown Select Type ──
          DropdownButtonFormField<String>(
            value: _type,
            items: [
              for (final t in IncidentTypes.all)
                DropdownMenuItem(
                  value: t,
                  child: Text(
                    IncidentTypes.label(t),
                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w500),
                  ),
                )
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: RmTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Type',
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: RmTheme.textSecondary,
              ),
              filled: true,
              fillColor: RmTheme.cardSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: RmTheme.electricBlue, width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // ── Title Input Field ──
          TextFormField(
            controller: _titleController,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: RmTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: RmTheme.textSecondary,
              ),
              filled: true,
              fillColor: RmTheme.cardSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: RmTheme.electricBlue, width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // ── Description Input Field ──
          TextFormField(
            controller: _descController,
            maxLines: 3,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: RmTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: RmTheme.textSecondary,
              ),
              filled: true,
              fillColor: RmTheme.cardSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: RmTheme.electricBlue, width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // ── Staff ID Input Field ──
          TextFormField(
            controller: _staffIdController,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: RmTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Staff ID (optional)',
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: RmTheme.textSecondary,
              ),
              filled: true,
              fillColor: RmTheme.cardSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: RmTheme.electricBlue, width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // ── File Incident Button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: RmTheme.electricBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'File Incident',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
