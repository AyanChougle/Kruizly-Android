import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/media_permission_helper.dart';
import '../../state/app_providers.dart';
import '../../state/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';

class HostCarScreen extends ConsumerStatefulWidget {
  const HostCarScreen({super.key});

  @override
  ConsumerState<HostCarScreen> createState() => _HostCarScreenState();
}

class _HostCarScreenState extends ConsumerState<HostCarScreen> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController(text: '2023');
  final _regNoController = TextEditingController();
  final _cityController = TextEditingController(text: 'Navi Mumbai');
  final _expectedPriceController = TextEditingController();

  String _transmission = 'Automatic';
  String _fuel = 'Petrol';
  final List<File> _localPhotos = [];
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _regNoController.dispose();
    _cityController.dispose();
    _expectedPriceController.dispose();
    super.dispose();
  }

  void _pickPhoto() {
    MediaPermissionHelper.showMediaSourceSheet(
      context: context,
      title: 'Vehicle Condition Photo',
      onImageSelected: (file) {
        setState(() => _localPhotos.add(file));
      },
    );
  }

  Future<void> _submitCar() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first to host your vehicle.'),
        ),
      );
      context.push('/sign-in');
      return;
    }

    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final regNo = _regNoController.text.trim();
    final priceStr = _expectedPriceController.text.trim();

    if (brand.isEmpty || model.isEmpty || regNo.isEmpty || priceStr.isEmpty) {
      setState(() => _error = 'Please fill in all mandatory fields.');
      return;
    }

    final price = double.tryParse(priceStr) ?? 0.0;
    final year = int.tryParse(_yearController.text.trim()) ?? 2023;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final repo = ref.read(partnerRepositoryProvider);
      List<String> uploadedUrls = [];

      for (final f in _localPhotos) {
        final url = await repo.uploadCarPhoto(f);
        if (url.isNotEmpty) uploadedUrls.add(url);
      }

      await repo.submitPartnerCar(
        brand: brand,
        model: model,
        year: year,
        regNo: regNo,
        transmission: _transmission,
        fuel: _fuel,
        city: _cityController.text.trim(),
        expectedPrice: price,
        photos: uploadedUrls,
      );

      setState(() => _isSubmitting = false);

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.themeSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: context.themeBorder),
          ),
          title: Text(
            'Car Listed Successfully!',
            style: TextStyle(color: context.themeTextPrimary),
          ),
          content: Text(
            'Your vehicle application has been submitted to the KRUIZLY fleet manager team. Our executive will contact you within 24 hours for physical verification and onboarding.',
            style: TextStyle(
              color: context.themeTextSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Back to Profile'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.themeTextPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Host Your Car',
          style: TextStyle(fontWeight: FontWeight.w700, color: context.themeTextPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earn with Your Idle Car',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Partner your car with KRUIZLY. Guaranteed monthly earnings, full insurance protection, and vetted verified renters.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.themeTextSecondary,
                      height: 1.3,
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
                  Text(
                    'Vehicle Information',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _brandController,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Make / Brand *',
                            hintText: 'e.g. Hyundai',
                            labelStyle: TextStyle(
                              color: context.themeTextSecondary,
                            ),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _modelController,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Model *',
                            hintText: 'e.g. Creta SX',
                            labelStyle: TextStyle(
                              color: context.themeTextSecondary,
                            ),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Manufacturing Year *',
                            labelStyle: TextStyle(
                              color: context.themeTextSecondary,
                            ),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _regNoController,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Reg Number *',
                            hintText: 'MH43AA1234',
                            labelStyle: TextStyle(
                              color: context.themeTextSecondary,
                            ),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _transmission,
                          dropdownColor: context.themeSurfaceElevated,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Transmission',
                            labelStyle: TextStyle(
                              color: context.themeTextSecondary,
                            ),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Automatic',
                              child: Text('Automatic'),
                            ),
                            DropdownMenuItem(
                              value: 'Manual',
                              child: Text('Manual'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _transmission = v ?? 'Automatic'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _fuel,
                          dropdownColor: context.themeSurfaceElevated,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Fuel Type',
                            labelStyle: TextStyle(
                              color: context.themeTextSecondary,
                            ),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Petrol',
                              child: Text('Petrol'),
                            ),
                            DropdownMenuItem(
                              value: 'Diesel',
                              child: Text('Diesel'),
                            ),
                            DropdownMenuItem(
                              value: 'Electric',
                              child: Text('Electric'),
                            ),
                            DropdownMenuItem(value: 'CNG', child: Text('CNG')),
                          ],
                          onChanged: (v) =>
                              setState(() => _fuel = v ?? 'Petrol'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'City / Location *',
                            labelStyle: TextStyle(
                              color: context.themeTextSecondary,
                            ),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _expectedPriceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Expected Daily Rent (₹) *',
                            hintText: 'e.g. 3500',
                            labelStyle: TextStyle(
                              color: context.themeTextSecondary,
                            ),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vehicle Photos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(
                          Icons.add_a_photo_outlined,
                          size: 16,
                          color: AppColors.primaryLight,
                        ),
                        label: const Text(
                          'Add Photo',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_localPhotos.isEmpty)
                    const Text(
                      'No photos added yet. Clear exterior & interior photos speed up approval.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  else
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _localPhotos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, idx) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _localPhotos[idx],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _localPhotos.removeAt(idx),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: 'Submit Vehicle Listing',
              isLoading: _isSubmitting,
              onPressed: _submitCar,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
