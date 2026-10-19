import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/media_permission_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/image_preview_dialog.dart';

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

  String _resolveFullUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '${AppConfig.mediaBaseUrl}$cleanPath';
  }

  void _openPreview(BuildContext context) {
    if (selectedFile != null || (existingUrl != null && existingUrl!.isNotEmpty)) {
      ImagePreviewDialog.show(
        context,
        file: selectedFile,
        imageUrl: existingUrl,
        title: title,
        subtitle: selectedFile != null
            ? 'Local file selected from device'
            : 'Stored securely on Kruizly server',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile =
        selectedFile != null || (existingUrl != null && existingUrl!.isNotEmpty);
    final isPdf = (selectedFile?.path.toLowerCase().endsWith('.pdf') ?? false) ||
        (existingUrl?.toLowerCase().contains('.pdf') ?? false);

    return Container(
      decoration: BoxDecoration(
        color: context.themeSurfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFile
              ? AppColors.success.withValues(alpha: 0.6)
              : context.themeBorder,
          width: hasFile ? 1.2 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (hasFile) {
              _openPreview(context);
            } else {
              MediaPermissionHelper.showMediaSourceSheet(
                context: context,
                title: 'Upload $title',
                onImageSelected: onFilePicked,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail or Icon preview
                GestureDetector(
                  onTap: hasFile ? () => _openPreview(context) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: hasFile
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasFile
                              ? AppColors.success.withValues(alpha: 0.3)
                              : Colors.white12,
                        ),
                      ),
                      child: selectedFile != null
                          ? (isPdf
                              ? const Center(
                                  child: Icon(Icons.picture_as_pdf_rounded,
                                      color: Color(0xFFEF4444), size: 28),
                                )
                              : Image.file(
                                  selectedFile!,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.insert_drive_file_outlined,
                                    color: AppColors.primaryLight,
                                  ),
                                ))
                          : (existingUrl != null && existingUrl!.isNotEmpty)
                              ? (isPdf
                                  ? const Center(
                                      child: Icon(Icons.picture_as_pdf_rounded,
                                          color: Color(0xFFEF4444), size: 28),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: _resolveFullUrl(existingUrl!),
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, _, _) => const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                        size: 26,
                                      ),
                                    ))
                              : const Center(
                                  child: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: AppColors.primaryLight,
                                    size: 24,
                                  ),
                                ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Titles and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: context.themeTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasFile)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check,
                                      size: 11, color: AppColors.success),
                                  SizedBox(width: 3),
                                  Text(
                                    'ATTACHED',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasFile
                            ? (selectedFile != null
                                ? '✓ New photo selected • Tap to preview'
                                : '✓ Verified on file • Tap to preview')
                            : subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: hasFile
                              ? AppColors.success
                              : context.themeTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action Buttons
                if (hasFile) ...[
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined,
                        size: 20, color: AppColors.primaryLight),
                    tooltip: 'Preview Document',
                    onPressed: () => _openPreview(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: context.themeTextSecondary),
                    tooltip: 'Change Document',
                    onPressed: () {
                      MediaPermissionHelper.showMediaSourceSheet(
                        context: context,
                        title: 'Upload $title',
                        onImageSelected: onFilePicked,
                      );
                    },
                  ),
                ] else ...[
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: context.themeTextMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
