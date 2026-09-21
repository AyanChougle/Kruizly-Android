import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/kyc_model.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

class ProfileState {
  final bool isLoading;
  final bool isSubmitting;
  final KycModel? kyc;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.kyc,
    this.errorMessage,
    this.successMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    KycModel? kyc,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      kyc: kyc ?? this.kyc,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const ProfileState()) {
    fetchKyc();
  }

  Future<void> fetchKyc() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final repo = _ref.read(kycRepositoryProvider);
      final kyc = await repo.getMyVerification();
      state = state.copyWith(isLoading: false, kyc: kyc);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<String?> uploadDocument(File file, String category) async {
    try {
      final repo = _ref.read(kycRepositoryProvider);
      return await repo.uploadKycDocument(file, category);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Upload failed: $e');
      return null;
    }
  }

  Future<bool> submitKyc({
    required String fullName,
    required String phone,
    String? licenseNumber,
    String? licenseFrontMediaId,
    String? licenseBackMediaId,
    String? aadharNumber,
    String? aadharFrontMediaId,
    String? aadharBackMediaId,
    String? panNumber,
    String? panFrontMediaId,
    String? panBackMediaId,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    try {
      final repo = _ref.read(kycRepositoryProvider);
      await repo.submitVerification(
        fullName: fullName,
        phone: phone,
        licenseNumber: licenseNumber,
        licenseFrontMediaId: licenseFrontMediaId,
        licenseBackMediaId: licenseBackMediaId,
        aadharNumber: aadharNumber,
        aadharFrontMediaId: aadharFrontMediaId,
        aadharBackMediaId: aadharBackMediaId,
        panNumber: panNumber,
        panFrontMediaId: panFrontMediaId,
        panBackMediaId: panBackMediaId,
      );
      await fetchKyc();
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'KYC documents submitted successfully for verification!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateProfile({required String name, required String phone}) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.updateProfile(name: name, phone: phone);
      await _ref.read(authProvider.notifier).refreshProfile();
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Profile updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});
