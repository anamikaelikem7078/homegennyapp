import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Upload a new staff document.
class StaffUploadDocumentScreen extends ConsumerStatefulWidget {
  const StaffUploadDocumentScreen({super.key});

  @override
  ConsumerState<StaffUploadDocumentScreen> createState() =>
      _StaffUploadDocumentScreenState();
}

class _StaffUploadDocumentScreenState extends ConsumerState<StaffUploadDocumentScreen> {
  final _nameController = TextEditingController();
  String? _documentType;
  List<PlatformFile> _pickedFiles = [];
  bool _isSubmitting = false;

  static const _documentTypes = ['Aadhaar Card', 'PAN Card', 'Address Proof', 'Police Verification', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _fileTypeFromName(String name) {
    final ext = name.split('.').last.toUpperCase();
    if (ext == 'PDF' || ext == 'DOC' || ext == 'DOCX' || ext == 'XLS' || ext == 'XLSX') {
      return ext.length <= 4 ? ext : 'FILE';
    }
    return 'FILE';
  }

  Future<void> _upload() async {
    if (_pickedFiles.isEmpty) {
      context.showDsSnackBar(
        'Please select a document to upload',
        type: DsSnackBarType.warning,
      );
      return;
    }
    if (_documentType == null) {
      context.showDsSnackBar(
        'Please select a document type',
        type: DsSnackBarType.warning,
      );
      return;
    }

    final file = _pickedFiles.first;
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : _documentType!;
    final type = _fileTypeFromName(file.name);

    setState(() => _isSubmitting = true);
    final result = await ref.read(staffRepositoryProvider).uploadDocument(
          name,
          type,
          kIsWeb ? file.name : (file.path ?? file.name),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffDocumentsProvider);
        context.showDsSnackBar(
          'Document uploaded successfully',
          type: DsSnackBarType.success,
        );
        context.go(StaffRoutes.documents);
      },
      onError: (failure) {
        context.showDsSnackBar(failure.message, type: DsSnackBarType.error);
      },
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'xls', 'xlsx'],
    );
    if (result != null) {
      setState(() {
        _pickedFiles = result.files;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Document',
              style: GoogleFonts.libreCaslonText(
                color: const Color(0xFF1A56FF),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Submit a new file for review',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                // Input Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document type',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: Text(
                              'Select type',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            value: _documentType,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF475569)),
                            items: _documentTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _documentType = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Document name (optional)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _nameController,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Aadhaar Card front',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF475569)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Select File Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select file',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomPaint(
                            painter: _DashedRectPainter(color: const Color(0xFFCBD5E1)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.upload_file,
                                    size: 32,
                                    color: Color(0xFF1A56FF),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _pickedFiles.isNotEmpty ? _pickedFiles.first.name : 'Upload document',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.libreCaslonText(
                                    fontSize: 18,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'PDF, DOC, XLS\nsupported (Max 10MB)',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF94A3B8),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _upload,
                    icon: _isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 20),
                    label: Text(
                      'Upload Document',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56FF),
                      disabledBackgroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Footer
                Text(
                  'HomeGenny v2.4 • End-to-end Encrypted Submission',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    
    // Top border
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
    
    // Right border
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
    
    // Bottom border
    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(Offset(startX, size.height), Offset(startX - dashWidth, size.height), paint);
      startX -= dashWidth + dashSpace;
    }
    
    // Left border
    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
