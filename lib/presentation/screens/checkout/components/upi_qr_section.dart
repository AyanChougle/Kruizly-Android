import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/glass_card.dart';

class UpiQrSection extends StatelessWidget {
  final String bookingId;
  final double amount;

  const UpiQrSection({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  String get _upiPayload {
    final upiId = AppConfig.upiId;
    final merchant = Uri.encodeComponent(AppConfig.upiName);
    final note = Uri.encodeComponent('Kruizly $bookingId');
    return 'upi://pay?pa=$upiId&pn=$merchant&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$note';
  }

  Future<void> _openUpiIntent(BuildContext context) async {
    final uri = Uri.parse(_upiPayload);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No UPI app found. Please scan the QR code or copy UPI ID.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch UPI app. Please scan the QR code.'),
          ),
        );
      }
    }
  }

  void _copyUpiId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: AppConfig.upiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UPI ID copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Scan & Pay via any UPI App',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'GPay, PhonePe, Paytm, BHIM, Cred, or any Bank App',
            style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: _upiPayload,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.themeSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.themeBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPI ID',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.themeTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppConfig.upiId,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Copy UPI ID',
                  icon: const Icon(
                    Icons.copy,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                  onPressed: () => _copyUpiId(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Pay via UPI App (Instant)',
            icon: Icons.account_balance_wallet_outlined,
            isOutlined: true,
            height: 44,
            onPressed: () => _openUpiIntent(context),
          ),
        ],
      ),
    );
  }
}
