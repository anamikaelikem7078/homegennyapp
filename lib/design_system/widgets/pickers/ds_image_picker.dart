import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../foundations/app_decorations.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Image picker widget with camera and gallery options.
class DsImagePicker extends StatefulWidget {
  const DsImagePicker({
    super.key,
    required this.onImagePicked,
    this.label,
    this.initialImage,
    this.height = 160,
  });

  final ValueChanged<File> onImagePicked;
  final String? label;
  final File? initialImage;
  final double height;

  @override
  State<DsImagePicker> createState() => _DsImagePickerState();
}

class _DsImagePickerState extends State<DsImagePicker> {
  final _picker = ImagePicker();
  File? _image;

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      final file = File(picked.path);
      setState(() => _image = file);
      widget.onImagePicked(file);
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined),
              title: Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined),
              title: Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          SizedBox(height: AppSpacing.xs),
        ],
        GestureDetector(
          onTap: _showSourceSheet,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: AppDecorations.softCard(context).copyWith(
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: _image != null
                ? ClipRRect(
                    borderRadius: AppRadius.lgAll,
                    // `dart:io` File isn't backed by real filesystem access
                    // on Flutter Web — `Image.file` asserts there. On web,
                    // `image_picker`'s picked path is actually a `blob:`
                    // URL, which `Image.network` can load directly.
                    child: kIsWeb
                        ? Image.network(_image!.path, fit: BoxFit.cover)
                        : Image.file(_image!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tap to upload image',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
