import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';

class MediaPermissionHelper {
  static Future<File?> pickImageWithPermission({
    required BuildContext context,
    required ImageSource source,
    int imageQuality = 85,
  }) async {
    try {
      // 1. Request appropriate permission based on source
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          if (context.mounted) _showSettingsDialog(context, 'Camera');
          return null;
        } else if (!status.isGranted && !status.isLimited) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera permission is required to capture photos.')),
            );
          }
          return null;
        }
      } else {
        // Gallery / Media permission
        // For Android 13+ (photos), fallback to storage on older versions
        PermissionStatus status = await Permission.photos.request();
        if (!status.isGranted && !status.isLimited) {
          status = await Permission.storage.request();
        }

        if (status.isPermanentlyDenied) {
          if (context.mounted) _showSettingsDialog(context, 'Photo Gallery');
          return null;
        }
      }

      // 2. Launch Image Picker
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );

      if (picked != null) {
        return File(picked.path);
      }
      return null;
    } catch (_) {
      // Graceful fallback for web/desktop/headless test environments
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source,
          imageQuality: imageQuality,
        );
        if (picked != null) return File(picked.path);
      } catch (_) {}
      return null;
    }
  }

  static void showMediaSourceSheet({
    required BuildContext context,
    required String title,
    required ValueChanged<File> onImageSelected,
  }) {
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
                title,
                style: TextStyle(
                  color: context.themeTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select camera to snap an ID or browse from your photo gallery.',
                style: TextStyle(
                  color: context.themeTextSecondary,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryLight),
                title: Text('Take with Camera', style: TextStyle(color: context.themeTextPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('Capture ID card or vehicle condition photo', style: TextStyle(color: context.themeTextMuted, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await pickImageWithPermission(
                    context: context,
                    source: ImageSource.camera,
                  );
                  if (file != null) onImageSelected(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryLight),
                title: Text('Choose from Gallery', style: TextStyle(color: context.themeTextPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('Upload saved photo or PDF receipt', style: TextStyle(color: context.themeTextMuted, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await pickImageWithPermission(
                    context: context,
                    source: ImageSource.gallery,
                  );
                  if (file != null) onImageSelected(file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showSettingsDialog(BuildContext context, String permissionType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeSurface,
        title: Text('$permissionType Permission Required', style: TextStyle(color: context.themeTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          '$permissionType access was permanently denied. Please allow it in App Settings to upload identity documents or capture inspection photos.',
          style: TextStyle(color: context.themeTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
