import os
import re

target_dir = r"c:\Users\dell\Desktop\Flutter\homegennyapp\lib"

replacements = [
    # Backgrounds
    (r"backgroundColor:\s*const\s*Color\(0xFFFBF9F8\)", "backgroundColor: context.theme.scaffoldBackgroundColor"),
    (r"backgroundColor:\s*const\s*Color\(0xFFFFFFFF\)", "backgroundColor: context.theme.cardColor"),
    (r"color:\s*const\s*Color\(0xFFFBF9F8\)", "color: context.theme.scaffoldBackgroundColor"),
    (r"color:\s*Colors\.white", "color: context.theme.cardColor"),
    
    # Text colors
    (r"color:\s*Colors\.black87", "color: context.colors.onSurface"),
    (r"color:\s*Colors\.black54", "color: context.colors.onSurfaceVariant"),
    
    # Borders & Fills
    (r"color:\s*const\s*Color\(0xFFE5E7EB\)", "color: context.theme.dividerColor"),
    (r"color:\s*const\s*Color\(0xFFF3F4F6\)", "color: context.colors.surfaceVariant"),
    (r"color:\s*Colors\.grey\.shade300", "color: context.theme.dividerColor"),
    (r"color:\s*Colors\.grey\.shade100", "color: context.colors.surfaceVariant"),
]

def replace_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
        
    if content != original:
        # If replacements were made, ensure context_extensions is imported if context.theme/colors is used
        if "context.theme" in content or "context.colors" in content:
            if "import '../../../../../core/extensions/context_extensions.dart';" not in content and \
               "import '../../../../core/extensions/context_extensions.dart';" not in content and \
               "import '../../../core/extensions/context_extensions.dart';" not in content and \
               "import '../../core/extensions/context_extensions.dart';" not in content and \
               "import '../core/extensions/context_extensions.dart';" not in content and \
               "import 'core/extensions/context_extensions.dart';" not in content and \
               "context_extensions.dart" not in content:
                
                # Try to determine the relative path based on the directory depth
                rel_path = os.path.relpath(r"c:\Users\dell\Desktop\Flutter\homegennyapp\lib\core\extensions\context_extensions.dart", os.path.dirname(filepath))
                rel_path = rel_path.replace('\\', '/')
                import_stmt = f"import '{rel_path}';"
                
                if "import 'package:flutter/material.dart';" in content:
                    content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_stmt}")
                else:
                    content = f"{import_stmt}\n{content}"

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(target_dir):
    for file in files:
        if file.endswith('.dart'):
            replace_in_file(os.path.join(root, file))

print("Done")
