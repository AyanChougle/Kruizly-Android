import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import 'components/kyc_upload_tile.dart';

class KycVerificationScreen extends ConsumerStatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  ConsumerState<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends ConsumerState<KycVerificationScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dlNumberController = TextEditingController();
  final _aadharNumberController = TextEditingController();
  final _panNumberController = TextEditingController();

  File? _dlFront;
  File? _dlBack;
  File? _aadharFront;
  File? _aadharBack;
  File? _panFront;
  File? _panBack;

  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      final kyc = ref.read(profileProvider).kyc;

      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.phone ?? '';
      }
      if (kyc != null) {
        if (kyc.licenseNumber != null) _dlNumberController.text = kyc.licenseNumber!;
        if (kyc.aadharNumber != null) _aadharNumberController.text = kyc.aadharNumber!;
        if (kyc.panNumber != null) _panNumberController.text = kyc.panNumber!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dlNumberController.dispose();
    _aadharNumberController.dispose();
    _panNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      setState(() => _errorMessage = 'Name and Phone number are required.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final profileNotifier = ref.read(profileProvider.notifier);

      String? dlFrontId;
      String? dlBackId;
      String? aadharFrontId;
      String? aadharBackId;
      String? panFrontId;
      String? panBackId;

      if (_dlFront != null) dlFrontId = await profileNotifier.uploadDocument(_dlFront!, 'driving_license_front');
      if (_dlBack != null) dlBackId = await profileNotifier.uploadDocument(_dlBack!, 'driving_license_back');
      if (_aadharFront != null) aadharFrontId = await profileNotifier.uploadDocument(_aadharFront!, 'aadhar_front');
      if (_aadharBack != null) aadharBackId = await profileNotifier.uploadDocument(_aadharBack!, 'aadhar_back');
      if (_panFront != null) panFrontId = await profileNotifier.uploadDocument(_panFront!, 'pan_front');
      if (_panBack != null) panBackId = await profileNotifier.uploadDocument(_panBack!, 'pan_back');

      final success = await profileNotifier.submitKyc(
        fullName: name,
        phone: phone,
        licenseNumber: _dlNumberController.text.trim().isNotEmpty ? _dlNumberController.text.trim() : null,
        licenseFrontMediaId: dlFrontId,
        licenseBackMediaId: dlBackId,
        aadharNumber: _aadharNumberController.text.trim().isNotEmpty ? _aadharNumberController.text.trim() : null,
        aadharFrontMediaId: aadharFrontId,
        aadharBackMediaId: aadharBackId,
        panNumber: _panNumberController.text.trim().isNotEmpty ? _panNumberController.text.trim() : null,
        panFrontMediaId: panFrontId,
        panBackMediaId: panBackId,
      );

      setState(() => _isUploading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC documents submitted successfully for review!')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final kyc = profileState.kyc;
    final status = kyc?.overallStatus ?? 'unverified';

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: context.themeTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('KYC Verification', style: TextStyle(fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.themeTextSecondary)),
                      const SizedBox(height: 2),
                      Text('Identity Verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                    ],
                  ),
                  StatusBadge(status: status),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personal Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: context.themeTextPrimary),
                    decoration: InputDecoration(
                      labelText: 'Full Legal Name *',
                      labelStyle: TextStyle(color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.themeBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.themeBorder)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: context.themeTextPrimary),
                    decoration: InputDecoration(
                      labelText: 'Contact Phone Number *',
                      labelStyle: TextStyle(color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.themeBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.themeBorder)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Driving License', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dlNumberController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(color: context.themeTextPrimary),
                    decoration: InputDecoration(
                      labelText: 'DL Number (e.g. MH0420180012345)',
                      labelStyle: TextStyle(color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.themeBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.themeBorder)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  KycUploadTile(
                    title: 'Driving License Front',
                    subtitle: 'Photo of the front face of your license',
                    selectedFile: _dlFront,
                    existingUrl: kyc?.licenseFrontUrl,
                    onFilePicked: (f) => setState(() => _dlFront = f),
                  ),
                  const SizedBox(height: 10),
                  KycUploadTile(
                    title: 'Driving License Back',
                    subtitle: 'Photo of the rear face showing address',
                    selectedFile: _dlBack,
                    existingUrl: kyc?.licenseBackUrl,
                    onFilePicked: (f) => setState(() => _dlBack = f),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2. Aadhaar / Government ID', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aadharNumberController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: context.themeTextPrimary),
                    decoration: InputDecoration(
                      labelText: '12-digit Aadhaar Number',
                      labelStyle: TextStyle(color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.themeBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.themeBorder)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  KycUploadTile(
                    title: 'Aadhaar Card Front',
                    subtitle: 'Clear photo showing name & photo',
                    selectedFile: _aadharFront,
                    existingUrl: kyc?.aadharFrontUrl,
                    onFilePicked: (f) => setState(() => _aadharFront = f),
                  ),
                  const SizedBox(height: 10),
                  KycUploadTile(
                    title: 'Aadhaar Card Back',
                    subtitle: 'Showing address & QR code',
                    selectedFile: _aadharBack,
                    existingUrl: kyc?.aadharBackUrl,
                    onFilePicked: (f) => setState(() => _aadharBack = f),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('3. PAN Card (Optional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.themeTextPrimary)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _panNumberController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(color: context.themeTextPrimary),
                    decoration: InputDecoration(
                      labelText: 'PAN Number (e.g. ABCDE1234F)',
                      labelStyle: TextStyle(color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.themeBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.themeBorder)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  KycUploadTile(
                    title: 'PAN Card Photo',
                    subtitle: 'Front view of PAN card',
                    selectedFile: _panFront,
                    existingUrl: kyc?.panFrontUrl,
                    onFilePicked: (f) => setState(() => _panFront = f),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: 'Submit KYC Documents',
              isLoading: _isUploading,
              onPressed: _handleSubmit,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
