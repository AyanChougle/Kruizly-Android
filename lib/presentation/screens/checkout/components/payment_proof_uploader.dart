import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/utils/media_permission_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/image_preview_dialog.dart';

class PaymentProofUploader extends StatefulWidget {
  final File? selectedFile;
  final Function(File? file) onFilePicked;

  const PaymentProofUploader({
    super.key,
    required this.selectedFile,
    required this.onFilePicked,
  });

  @override
  State<PaymentProofUploader> createState() => _PaymentProofUploaderState();
}

class _PaymentProofUploaderState extends State<PaymentProofUploader> {

  void _showPickerModal() {
    MediaPermissionHelper.showMediaSourceSheet(
      context: context,
      title: 'Upload Payment Screenshot',
      onImageSelected: widget.onFilePicked,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Receipt / Screenshot (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Attaching a screenshot speeds up automated UTR verification.',
            style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
          ),
          const SizedBox(height: 14),
          if (widget.selectedFile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.themeSurfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.themeBorderLight),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      ImagePreviewDialog.show(
                        context,
                        file: widget.selectedFile,
                        title: 'Payment Screenshot',
                        subtitle: widget.selectedFile!.path.split(Platform.pathSeparator).last,
                      );
                    },
                    child: Tooltip(
                      message: 'Tap to zoom preview',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.file(
                              widget.selectedFile!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              left: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: const Icon(Icons.zoom_in, size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ImagePreviewDialog.show(
                          context,
                          file: widget.selectedFile,
                          title: 'Payment Screenshot',
                          subtitle: widget.selectedFile!.path.split(Platform.pathSeparator).last,
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Screenshot Attached',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.themeTextPrimary),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.zoom_in, size: 14, color: AppColors.primaryLight),
                            ],
                          ),
                          Text(
                            widget.selectedFile!.path.split(Platform.pathSeparator).last,
                            style: TextStyle(fontSize: 11, color: context.themeTextMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    tooltip: 'Remove',
                    onPressed: () => widget.onFilePicked(null),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: _showPickerModal,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: context.themeSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.themeBorder, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primaryLight, size: 32),
                      const SizedBox(height: 6),
                      const Text(
                        'Upload Transfer Screenshot',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PNG, JPG up to 10MB',
                        style: TextStyle(fontSize: 11, color: context.themeTextMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
