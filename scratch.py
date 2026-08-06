import re

file_path = 'c:/Users/dell/Desktop/Flutter/homegennyapp/lib/features/staff/presentation/screens/home/staff_home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

if 'flutter_screenutil/flutter_screenutil.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_screenutil/flutter_screenutil.dart';")

def make_responsive(text):
    text = re.sub(r'(EdgeInsets\.(?:all|symmetric)\s*\([^)]*?(?:horizontal|vertical|value)?\s*:\s*)(\d+\.?\d*)', 
                  lambda m: m.group(1) + m.group(2) + ('.h' if 'vertical' in m.group(1) else '.w'), text)
    text = re.sub(r'(EdgeInsets\.only\s*\([^)]*?)(top|bottom|left|right)(\s*:\s*)(\d+\.?\d*)', 
                  lambda m: m.group(1) + m.group(2) + m.group(3) + m.group(4) + ('.h' if m.group(2) in ('top', 'bottom') else '.w'), text)
    
    text = re.sub(r'(height\s*:\s*)(\d+\.?\d*)', r'\1\2.h', text)
    text = re.sub(r'(width\s*:\s*)(\d+\.?\d*)', r'\1\2.w', text)
    text = re.sub(r'(fontSize\s*:\s*)(\d+\.?\d*)', r'\1\2.sp', text)
    text = re.sub(r'(size\s*:\s*)(\d+\.?\d*)', r'\1\2.sp', text)
    text = re.sub(r'(radius\s*:\s*)(\d+\.?\d*)', r'\1\2.r', text)
    text = re.sub(r'(Radius\.circular\s*\(\s*)(\d+\.?\d*)', r'\1\2.r', text)
    text = re.sub(r'(BorderRadius\.circular\s*\(\s*)(\d+\.?\d*)', r'\1\2.r', text)
    text = re.sub(r'(SizedBox\s*\(\s*height\s*:\s*)(\d+\.?\d*)', r'\1\2.h', text)
    text = re.sub(r'(SizedBox\s*\(\s*width\s*:\s*)(\d+\.?\d*)', r'\1\2.w', text)
    text = re.sub(r'(\.\w)\.\w', r'\1', text) # fix double
    return text

new_content = make_responsive(content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)
