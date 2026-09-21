import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_button.dart';

class CancelBookingDialog extends StatefulWidget {
  final String bookingId;
  final Function(String reason) onConfirm;

  const CancelBookingDialog({
    super.key,
    required this.bookingId,
    required this.onConfirm,
  });

  @override
  State<CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<CancelBookingDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.themeSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.themeBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancel Booking?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.themeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to cancel booking #${widget.bookingId}? Any eligible refund will be processed according to KRUIZLY cancellation terms.',
              style: TextStyle(fontSize: 13, color: context.themeTextSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              style: TextStyle(color: context.themeTextPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for cancellation',
                labelStyle: TextStyle(color: context.themeTextSecondary, fontSize: 13),
                hintText: 'e.g. Plans changed, date adjustment...',
                hintStyle: TextStyle(color: context.themeTextMuted, fontSize: 13),
                filled: true,
                fillColor: context.themeSurfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.themeBorder),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Keep Trip',
                    isOutlined: true,
                    height: 44,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Confirm Cancel',
                    backgroundColor: AppColors.error,
                    isLoading: _isLoading,
                    height: 44,
                    onPressed: () {
                      setState(() => _isLoading = true);
                      widget.onConfirm(_reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : 'User requested cancellation');
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
