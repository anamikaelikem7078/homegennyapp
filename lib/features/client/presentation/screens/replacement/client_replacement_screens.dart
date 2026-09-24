import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../widgets/client_scaffold.dart';

/// Replacement request form.
class ClientReplacementRequestScreen extends ConsumerStatefulWidget {
  const ClientReplacementRequestScreen({super.key});

  @override
  ConsumerState<ClientReplacementRequestScreen> createState() =>
      _ClientReplacementRequestScreenState();
}

class _ClientReplacementRequestScreenState
    extends ConsumerState<ClientReplacementRequestScreen> {
  final _reason = TextEditingController();
  bool _loading = false;
  String _urgency = 'STANDARD';
  String? _pickedFileName;
  // Placement to replace — required once the client has more than one staff
  // member placed; the backend 400s with "send placement_id to say which
  // one" if it's ambiguous. `staffId` from GET /client/assigned-staff is the
  // only per-placement identifier that model exposes, so it's reused here.
  String? _selectedPlacementId;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFileName = result.files.first.name;
      });
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) {
      context.showDsSnackBar('Please provide a reason', type: DsSnackBarType.warning);
      return;
    }
    final assignedStaff = await ref.read(clientAssignedStaffProvider.future);
    if (!mounted) return;
    if (assignedStaff.length > 1 && _selectedPlacementId == null) {
      context.showDsSnackBar(
        'You have more than one staff member placed — please pick who this is for',
        type: DsSnackBarType.warning,
      );
      return;
    }
    final placementId = _selectedPlacementId ??
        (assignedStaff.length == 1 ? assignedStaff.first.staffId : null);
    setState(() => _loading = true);
    final result = await ref.read(clientRepositoryProvider).requestReplacement(
          reason: _reason.text,
          placementId: placementId,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (r) {
        ref.invalidate(clientReplacementsProvider);
        context.showDsSnackBar(r.message, type: DsSnackBarType.success);
        context.go(ClientRoutes.replacementStatus);
      },
      // A 400 asking to disambiguate the placement (or any other server
      // error) is surfaced verbatim rather than guessed at client-side.
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF000101)),
          onPressed: () {
            // `canPop()` is false whenever this screen is the only stack
            // entry — a browser refresh/direct URL load leaves nothing to
            // pop back to. Popping unconditionally in that case can throw.
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(ClientRoutes.dashboard);
            }
          },
        ),
        title: Text(
          'HOMEGENNY',
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            letterSpacing: 2,
            color: const Color(0xFF000101),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAa4W3szKskOmkawO2a_LeP4GZI5MfpdAe7CNR-S_y1Q2Cbok1TRKElTyRH4q0BqALPoxR5Us6QELLH-GNnHV6uxxTjWEP78dncobxN91qbSGJxFtLnjoU7DmrenpmwVyD2Iee55IBGCUrX1fJ_JX3B2a9Zyn00hDJ5hE--mQzojfXKWGebkI4aNcVjyfn_NSyumAAVWK4m_LZBt5MO1cYb8LmD8XhGI-yvtFl1otq809YOZo2Aoxsr'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF735A3A).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
            right: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Experience an issue?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 32,
                      color: const Color(0xFF000101),
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Our dedicated support team is ready to provide a seamless resolution for your concierge needs.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: const Color(0xFF735A3A),
                    ),
                  ),
                  SizedBox(height: 48),
                  Consumer(
                    builder: (context, ref, _) {
                      final assignedStaff = ref.watch(clientAssignedStaffProvider);
                      return assignedStaff.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (staff) {
                          if (staff.length <= 1) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WHICH STAFF MEMBER?',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: const Color(0xFF735A3A),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F4F7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      hint: Text(
                                        'Select a staff member',
                                        style: GoogleFonts.manrope(fontSize: 14),
                                      ),
                                      value: _selectedPlacementId,
                                      items: [
                                        for (final s in staff)
                                          DropdownMenuItem(
                                            value: s.staffId,
                                            child: Text(
                                              s.fullName ?? s.staffCode ?? s.staffId,
                                              style: GoogleFonts.manrope(fontSize: 14),
                                            ),
                                          ),
                                      ],
                                      onChanged: (v) => setState(() => _selectedPlacementId = v),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Text(
                    'DESCRIBE THE ISSUE',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: const Color(0xFF735A3A),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _reason,
                      maxLines: 5,
                      style: GoogleFonts.manrope(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Detail the nature of the problem...',
                        hintStyle: GoogleFonts.manrope(
                          fontSize: 16,
                          color: const Color(0xFFC5C6CA),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'URGENCY LEVEL',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: const Color(0xFF735A3A),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildUrgencyButton('LOW'),
                      SizedBox(width: 12),
                      _buildUrgencyButton('STANDARD'),
                      SizedBox(width: 12),
                      _buildUrgencyButton('CRITICAL'),
                    ],
                  ),
                  SizedBox(height: 32),
                  GestureDetector(
                    onTap: _pickDocument,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFC5C6CA).withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: _pickedFileName != null ? const Color(0xFFF2F4F7) : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _pickedFileName != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                            size: 40,
                            color: _pickedFileName != null ? const Color(0xFF2563EB) : const Color(0xFFC5C6CA),
                          ),
                          SizedBox(height: 12),
                          Text(
                            _pickedFileName ?? 'Upload Documents',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _pickedFileName != null ? const Color(0xFF2563EB) : const Color(0xFF000101),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_pickedFileName == null) ...[
                            SizedBox(height: 4),
                            Text(
                              'JPEG, PNG, or PDF (Max 10MB)',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: const Color(0xFF735A3A).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // support-blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: _loading 
                        ? SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(color: context.theme.cardColor, strokeWidth: 2)
                          )
                        : Text(
                            'SUBMIT ISSUE',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                  SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F3),
                      border: Border.all(color: const Color(0xFFC5C6CA).withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: context.theme.cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.support_agent,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Priority Handling',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF000101),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Our elite team responds within 15 minutes for critical issues.',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: const Color(0xFF735A3A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyButton(String label) {
    final isActive = _urgency == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _urgency = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF000101) : Colors.transparent,
            border: Border.all(
              color: isActive ? const Color(0xFF000101) : const Color(0xFFC5C6CA),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF000101),
            ),
          ),
        ),
      ),
    );
  }
}

/// Replacement status.
class ClientReplacementStatusScreen extends ConsumerWidget {
  const ClientReplacementStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replacements = ref.watch(clientReplacementsProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.onSurface),
          onPressed: () {
            // `canPop()` is false whenever this screen is the only stack
            // entry — a browser refresh/direct URL load, or arriving here
            // straight from a push-replacement flow — leaving nothing to
            // pop back to. Without a fallback, back does nothing.
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(ClientRoutes.dashboard);
            }
          },
        ),
        title: Text(
          'Replacement Status',
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: replacements.when(
        loading: () => Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
        error: (_, __) => Center(
          child: Text(
            'Error loading status',
            style: GoogleFonts.manrope(color: Colors.red),
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.find_replace_rounded,
                        size: 64,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(height: 32),
                    Text(
                      'No Active Request',
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 24,
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'You currently have no active replacement requests for your staff.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: context.colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => context.push(ClientRoutes.replacementRequest),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'REQUEST REPLACEMENT',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final request in requests) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'STATUS',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: const Color(0xFF735A3A),
                            ),
                          ),
                          DsStatusChip(
                            label: clientReplacementStatusLabel(request.status),
                            type: clientReplacementStatusType(request.status),
                          ),
                        ],
                      ),
                      if (request.currentStaffName.isNotEmpty) ...[
                        SizedBox(height: 24),
                        Text(
                          'Current Staff',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF735A3A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          request.currentStaffName,
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 18,
                            color: const Color(0xFF000101),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (request.requestedAt.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'Requested On',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF735A3A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          request.requestedAt,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: const Color(0xFF000101),
                          ),
                        ),
                      ],
                      if (request.newStaffName != null) ...[
                        SizedBox(height: 16),
                        Text(
                          'New Staff',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF735A3A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          request.newStaffName!,
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 18,
                            color: const Color(0xFF000101),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (request.estimatedDate != null) ...[
                        SizedBox(height: 16),
                        Text(
                          'Estimated Date',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF735A3A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          request.estimatedDate!,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: const Color(0xFF000101),
                          ),
                        ),
                      ],
                      if (request.reason.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'Reason',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF735A3A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          request.reason,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: const Color(0xFF000101),
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (request.remarks != null) ...[
                        SizedBox(height: 16),
                        Text(
                          'Remarks',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF735A3A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          request.remarks!,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: const Color(0xFF000101),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              Center(
                child: TextButton(
                  onPressed: () => context.push(ClientRoutes.replacementRequest),
                  child: Text(
                    'FILE ANOTHER REQUEST',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
