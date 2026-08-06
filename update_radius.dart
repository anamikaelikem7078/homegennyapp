import 'dart:io';

void main() {
  final staffFile = File('lib/features/client/presentation/screens/staff/client_staff_screens.dart');
  var content = staffFile.readAsStringSync();

  // Avatar in Tab screen
  content = content.replaceFirst('borderRadius: BorderRadius.circular(24)', 'borderRadius: BorderRadius.circular(4)');
  content = content.replaceFirst('borderRadius: BorderRadius.circular(20)', 'borderRadius: BorderRadius.circular(4)');
  
  // Avatar in Profile screen
  content = content.replaceFirst('borderRadius: BorderRadius.circular(16),\n                  border: Border.all(color: Colors.grey.shade300, width: 1)', 'borderRadius: BorderRadius.circular(4),\n                  border: Border.all(color: Colors.grey.shade300, width: 1)');
  content = content.replaceFirst('borderRadius: BorderRadius.circular(12),\n                  child: Image.network', 'borderRadius: BorderRadius.circular(4),\n                  child: Image.network');

  // Name color in Profile Screen
  content = content.replaceFirst(
    'style: GoogleFonts.libreCaslonText(\n                  fontSize: 32,\n                  color: const Color(0xFF1A56FF),\n                  fontWeight: FontWeight.w500,\n                ),',
    'style: GoogleFonts.libreCaslonText(\n                  fontSize: 32,\n                  color: Colors.black87,\n                  fontWeight: FontWeight.w500,\n                ),'
  );

  // General radius replacements for cards in staff screen
  content = content.replaceAll('borderRadius: BorderRadius.circular(16)', 'borderRadius: BorderRadius.circular(4)');
  content = content.replaceAll('borderRadius: BorderRadius.circular(12)', 'borderRadius: BorderRadius.circular(4)');
  content = content.replaceAll('borderRadius: BorderRadius.circular(8)', 'borderRadius: BorderRadius.circular(4)');
  content = content.replaceAll('borderRadius: BorderRadius.circular(20)', 'borderRadius: BorderRadius.circular(4)');

  staffFile.writeAsStringSync(content);
  
  final complaintFile = File('lib/features/client/presentation/screens/complaint/client_complaint_screens.dart');
  var complaintContent = complaintFile.readAsStringSync();
  
  complaintContent = complaintContent.replaceAll('borderRadius: BorderRadius.circular(16)', 'borderRadius: BorderRadius.circular(4)');
  complaintContent = complaintContent.replaceAll('borderRadius: BorderRadius.circular(8)', 'borderRadius: BorderRadius.circular(4)');
  
  // Title color in Complaint Screen
  complaintContent = complaintContent.replaceFirst(
    'style: GoogleFonts.libreCaslonText(\n              fontSize: 32,\n              color: const Color(0xFF1A56FF),\n              fontWeight: FontWeight.w500,\n            ),',
    'style: GoogleFonts.libreCaslonText(\n              fontSize: 32,\n              color: Colors.black87,\n              fontWeight: FontWeight.w500,\n            ),'
  );

  complaintFile.writeAsStringSync(complaintContent);
}
