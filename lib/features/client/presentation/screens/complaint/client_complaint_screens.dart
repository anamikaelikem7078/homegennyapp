import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/models/client_models.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../widgets/client_scaffold.dart';

/// Raise complaint form.
class ClientRaiseComplaintScreen extends ConsumerStatefulWidget {
  const ClientRaiseComplaintScreen({super.key});

  @override
  ConsumerState<ClientRaiseComplaintScreen> createState() =>
      _ClientRaiseComplaintScreenState();
}

class _ClientRaiseComplaintScreenState extends ConsumerState<ClientRaiseComplaintScreen> {
  final _description = TextEditingController();
  List<String> _imagePaths = [];
  bool _loading = false;
  
  String _urgency = 'STANDARD';

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_description.text.isEmpty) {
      context.showDsSnackBar(context.l10n.pleaseDescribeIssue, type: DsSnackBarType.warning);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(clientRepositoryProvider).raiseComplaint(
          subject: 'Support Request - $_urgency',
          description: _description.text,
          imagePaths: _imagePaths,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(clientComplaintsProvider);
        context.showDsSnackBar(context.l10n.issueSubmittedSuccess, type: DsSnackBarType.success);
        context.go(ClientRoutes.complaintHistory);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios, color: context.colors.onSurface),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Text(
          'HOMEGENNY',
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150'),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Text(
            context.l10n.experienceIssue,
            style: GoogleFonts.libreCaslonText(
              fontSize: 32,
              color: context.colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Text(
            context.l10n.supportTeamDesc,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          SizedBox(height: 40),
          
          Text(
            context.l10n.describeIssue,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF9E7C5D),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _description,
            maxLines: 5,
            style: GoogleFonts.inter(fontSize: 14, color: context.colors.onSurface),
            decoration: InputDecoration(
              hintText: context.l10n.detailProblemHint,
              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.black26),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF1A56FF)),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          SizedBox(height: 40),
          
          Text(
            context.l10n.urgencyLevel,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF9E7C5D),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _UrgencyButton(label: context.l10n.urgencyLow, isActive: _urgency == 'LOW', onTap: () => setState(() => _urgency = 'LOW'))),
              SizedBox(width: 8),
              Expanded(child: _UrgencyButton(label: context.l10n.urgencyStandard, isActive: _urgency == 'STANDARD', onTap: () => setState(() => _urgency = 'STANDARD'))),
              SizedBox(width: 8),
              Expanded(child: _UrgencyButton(label: context.l10n.urgencyCritical, isActive: _urgency == 'CRITICAL', onTap: () => setState(() => _urgency = 'CRITICAL'))),
            ],
          ),
          SizedBox(height: 40),
          
          GestureDetector(
            onTap: () async {
              final paths = await context.push<List<String>>(ClientRoutes.complaintUpload);
              if (paths != null) setState(() => _imagePaths = paths);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
                // Emulating a dashed border with a solid one for simplicity in basic flutter
                border: Border.all(color: context.theme.dividerColor, width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: Color(0xFF1A56FF), size: 32),
                  SizedBox(height: 12),
                  Text(
                    _imagePaths.isEmpty
                        ? context.l10n.uploadDocuments
                        : '${_imagePaths.length} image(s) attached',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF1A56FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    context.l10n.uploadDocsHint,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                disabledBackgroundColor: const Color(0xFF1A56FF).withOpacity(0.5),
              ),
              child: _loading 
                ? Icon(Icons.check, color: context.theme.cardColor)
                : Text(
                  context.l10n.submitIssue,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
            ),
          ),
          SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.headset_mic_outlined, color: Color(0xFF1A56FF), size: 20),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.priorityHandling,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF1A56FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        context.l10n.priorityHandlingDesc,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _UrgencyButton extends StatelessWidget {
  const _UrgencyButton({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          border: Border.all(color: isActive ? Colors.black : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Upload images for complaint.
class ClientComplaintUploadScreen extends StatefulWidget {
  const ClientComplaintUploadScreen({super.key});

  @override
  State<ClientComplaintUploadScreen> createState() => _ClientComplaintUploadScreenState();
}

class _ClientComplaintUploadScreenState extends State<ClientComplaintUploadScreen> {
  final List<String> _imagePaths = [];
  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() => _imagePaths.addAll(picked.map((f) => f.path)));
  }

  @override
  Widget build(BuildContext context) {
    return ClientPageScaffold(
      title: context.l10n.uploadImagesTitle,
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              children: [
                ..._imagePaths.map((path) => Container(
                      decoration: AppDecorations.softCard(context),
                      clipBehavior: Clip.antiAlias,
                      // `Image.file` asserts on Flutter Web; the picked
                      // path there is a `blob:` URL `Image.network` can load.
                      child: kIsWeb
                          ? Image.network(path, fit: BoxFit.cover)
                          : Image.file(File(path), fit: BoxFit.cover),
                    )),
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    decoration: AppDecorations.softCard(context),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
                        SizedBox(height: AppSpacing.xs),
                        Text(context.l10n.addPhoto),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          DsPrimaryButton(
            label: context.l10n.done,
            onPressed: () {
              context.showDsSnackBar(
                context.l10n.imagesAttached(_imagePaths.length),
                type: DsSnackBarType.success,
              );
              context.pop(_imagePaths);
            },
          ),
        ],
      ),
    );
  }
}

/// Complaint history.
class ClientComplaintHistoryScreen extends ConsumerWidget {
  const ClientComplaintHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaints = ref.watch(clientComplaintsProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.complaintHistoryTitle,
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ElevatedButton.icon(
          onPressed: () => context.push(ClientRoutes.complaintRaise),
          icon: Icon(Icons.add, size: 20),
          label: Text(
            context.l10n.newComplaintBtn,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56FF),
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: const Color(0xFF1A56FF).withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: complaints.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                context.l10n.noComplaintsFound,
                style: GoogleFonts.inter(color: context.colors.onSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(bottom: 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => SizedBox(height: 16),
            itemBuilder: (_, i) {
              final c = list[i];
              final isResolved = c.status == ClientComplaintStatus.resolved;
              final isInvestigation = c.status == ClientComplaintStatus.inProgress;
              
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.subject,
                      style: GoogleFonts.libreCaslonText(
                        color: context.colors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info, color: context.colors.onSurfaceVariant),
                        SizedBox(width: 4),
                        Text(
                          c.createdAt,
                          style: GoogleFonts.inter(
                            color: context.colors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('|', style: TextStyle(color: context.theme.dividerColor)),
                        ),
                        Text(
                          context.l10n.ref(c.id.hashCode.toString().substring(0, 4)),
                          style: GoogleFonts.inter(
                            color: context.colors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isResolved 
                            ? const Color(0xFF1A56FF).withOpacity(0.1) 
                            : isInvestigation 
                                ? Colors.grey.shade200 
                                : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        clientComplaintStatusLabel(c.status).toUpperCase(),
                        style: GoogleFonts.inter(
                          color: isResolved 
                              ? const Color(0xFF1A56FF)
                              : isInvestigation 
                                  ? Colors.black54
                                  : Colors.orange.shade800,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Description with left border
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(
                            width: 2,
                            color: context.theme.dividerColor,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.description,
                                  style: GoogleFonts.inter(
                                    color: context.colors.onSurface,
                                    fontSize: 12,
                                    height: 1.6,
                                  ),
                                ),
                                if (c.imageCount > 0) ...[
                                  SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&w=150&q=80',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (c.resolution != null && c.resolution!.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Color(0xFF1A56FF), size: 14),
                                SizedBox(width: 6),
                                Text(
                                  context.l10n.resolutionDetails,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF1A56FF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '"${c.resolution}"',
                              style: GoogleFonts.inter(
                                color: context.colors.onSurfaceVariant,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    if (!isResolved && c.imageCount > 0) ...[
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.info, color: context.colors.onSurfaceVariant),
                          SizedBox(width: 4),
                          Text(
                            '${c.imageCount} files',
                            style: GoogleFonts.inter(color: context.colors.onSurfaceVariant, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
