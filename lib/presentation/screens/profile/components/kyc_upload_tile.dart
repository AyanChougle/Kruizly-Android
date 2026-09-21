import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';

class KycUploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final File? selectedFile;
  final String? existingUrl;
  final Function(File file) onFilePicked;

  const KycUploadTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.selectedFile,
    this.existingUrl,
    required this.onFilePicked,
  });

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      onFilePicked(File(picked.path));
    }
  }

  void _showSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload $title',
                style: TextStyle(
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primaryLight,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: context.themeTextPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primaryLight,
                ),
                title: Text(
                  'Take with Camera',
                  style: TextStyle(color: context.themeTextPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFile =
        selectedFile != null ||
        (existingUrl != null && existingUrl!.isNotEmpty);

    return InkWell(
      onTap: () => _showSourceModal(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.themeSurfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile
                ? AppColors.success.withValues(alpha: 0.5)
                : context.themeBorder,
          ),
        ),
        child: Row(
          children: [
            if (selectedFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  selectedFile!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (hasFile ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasFile
                      ? Icons.check_circle_outline
                      : Icons.file_upload_outlined,
                  color: hasFile ? AppColors.success : AppColors.primaryLight,
                  size: 22,
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile
                        ? (selectedFile != null
                              ? 'Selected from device'
                              : 'Document uploaded on server')
                        : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile
                          ? AppColors.success
                          : context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: context.themeTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}
