import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';

class ImagePreviewDialog extends StatelessWidget {
  final File? file;
  final String? imageUrl;
  final String title;
  final String? subtitle;

  const ImagePreviewDialog({
    super.key,
    this.file,
    this.imageUrl,
    this.title = 'Document Preview',
    this.subtitle,
  });

  static Future<void> show(
    BuildContext context, {
    File? file,
    String? imageUrl,
    String title = 'Document Preview',
    String? subtitle,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => ImagePreviewDialog(
        file: file,
        imageUrl: imageUrl,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  bool get _isPdf {
    if (file != null) {
      return file!.path.toLowerCase().endsWith('.pdf');
    }
    if (imageUrl != null) {
      final lower = imageUrl!.toLowerCase();
      return lower.contains('.pdf') || lower.contains('ext=.pdf');
    }
    return false;
  }

  String _resolveFullUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '${AppConfig.mediaBaseUrl}$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final hasSource = file != null || (imageUrl != null && imageUrl!.isNotEmpty);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1527),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isPdf
                              ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _isPdf ? Icons.picture_as_pdf_rounded : Icons.photo_size_select_actual_outlined,
                          color: _isPdf ? const Color(0xFFF87171) : AppColors.primaryLight,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0x1FFFFFFF)),

                // Content View / Zoomable Image
                Flexible(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 250, maxHeight: 560),
                      color: const Color(0xFF060B14),
                      child: !hasSource
                          ? const Center(
                              child: Text(
                                'No document preview available',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : _isPdf
                              ? _buildPdfView(context)
                              : _buildImageView(),
                    ),
                  ),
                ),

                // Bottom Hint Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF090E1A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isPdf ? Icons.info_outline : Icons.pinch_outlined,
                            size: 14,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isPdf ? 'PDF Document format' : 'Pinch to zoom & pan',
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                      if (imageUrl != null && imageUrl!.isNotEmpty)
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse(_resolveFullUrl(imageUrl!));
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: const Row(
                            children: [
                              Text(
                                'Open Fullscreen',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.open_in_new, size: 12, color: AppColors.primaryLight),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageView() {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.5,
      clipBehavior: Clip.none,
      child: Center(
        child: file != null
            ? Image.file(
                file!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, size: 48, color: Colors.white30),
                    SizedBox(height: 8),
                    Text('Failed to load local image', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              )
            : CachedNetworkImage(
                imageUrl: _resolveFullUrl(imageUrl!),
                fit: BoxFit.contain,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                ),
                errorWidget: (_, _, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_outlined, size: 48, color: Colors.white30),
                    const SizedBox(height: 8),
                    const Text('Unable to preview document', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(imageUrl ?? '', style: const TextStyle(color: Colors.white24, fontSize: 10), textAlign: TextAlign.center),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPdfView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, size: 44, color: Color(0xFFF87171)),
            ),
            const SizedBox(height: 16),
            const Text(
              'PDF Identity Document',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              file != null
                  ? file!.path.split(Platform.pathSeparator).last
                  : 'Document stored on Kruizly secure host',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open & View PDF', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                onPressed: () async {
                  final uri = Uri.parse(_resolveFullUrl(imageUrl!));
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
