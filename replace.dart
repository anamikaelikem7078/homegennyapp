import 'dart:io';

void main() async {
  final dir = Directory('lib/features/rm/presentation/screens');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('rm_dashboard_screen.dart') || file.path.contains('rm_pipeline_screen.dart')) {
      continue;
    }

    String content = await file.readAsString();

    if (!content.contains('_buildBottomNav') && !content.contains('_buildFloatingBottomNav')) {
      continue;
    }

    // Add import if not present
    if (!content.contains('rm_bottom_navigation.dart')) {
      content = content.replaceFirst(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport '../widgets/rm_bottom_navigation.dart';"
      );
    }

    // Replace bottomNavigationBar usage
    content = content.replaceAll(
      RegExp(r'bottomNavigationBar:\s*_build(Floating)?BottomNav\([^)]*\),'),
      'bottomNavigationBar: const RmBottomNavigation(currentIndex: 0),'
    );

    // Remove _buildBottomNav and _buildFloatingBottomNav and _buildNavItem methods
    // This is a bit tricky with regex, we can try to find the start and end of the block.
    // Instead of regex for method removal which is error prone, we can just leave the dead code for now,
    // or use a simple regex that matches the method if it's at the end of the file.
    // In our case, these methods are always at the end of the class.
    
    // For a cleaner approach without a robust parser, let's just replace the bottomNavigationBar property 
    // and we'll manually clean up the files or leave the unused private methods which Dart analyzer will flag.
    // Actually, replacing the whole block is possible if we use a regex that matches from `Widget _buildBottomNav` to the end of the class `}`
    
    final navPattern = RegExp(r'Widget\s+_build(Floating)?BottomNav\([^)]*\)\s*\{[\s\S]*?Widget\s+_buildNavItem\([^)]*\)\s*\{[\s\S]*?\}\s*\}');
    content = content.replaceFirst(navPattern, '}');

    // Handle cases where the class closing brace might be duplicated or missed
    // A simpler way: we know it ends with _buildNavItem usually. Let's just write the changes.
    await file.writeAsString(content);
    print('Updated ${file.path}');
  }
}
