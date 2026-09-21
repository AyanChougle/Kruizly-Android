import '''dart:io''';
import '''package:dio/dio.dart''';
import '''../../core/constants/api_endpoints.dart''';
import '''../../core/errors/app_exceptions.dart''';
import '''../../core/network/api_client.dart''';
import '''../models/kyc_model.dart''';

class KycRepository {
  final ApiClient _apiClient;

  KycRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<KycModel> getMyVerification() async {
    final response = await _apiClient.get(ApiEndpoints.myVerification);
    if (response is Map<String, dynamic>) {
      return KycModel.fromJson(response);
    }
    throw const ServerException('''Failed to retrieve KYC status.''');
  }

  Future<String> uploadKycDocument(File file, String docCategory) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      '''file''': await MultipartFile.fromFile(file.path, filename: fileName),
      '''category''': docCategory,
    });

    final response = await _apiClient.uploadFile(
      ApiEndpoints.uploadMedia,
      formData: formData,
    );
    if (response is Map<String, dynamic> && response['''success'''] == true) {
      return (response['''mediaId'''] ?? response['''id''']).toString();
    }
    throw const ServerException('''Failed to upload identity document.''');
  }

  Future<void> submitVerification({
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
    final response = await _apiClient.post(
      ApiEndpoints.submitVerification,
      data: {
        '''fullName''': fullName,
        '''phone''': phone,
        '''licenseNumber''': ?licenseNumber,
        '''licenseFrontMediaId''': ?licenseFrontMediaId,
        '''licenseBackMediaId''': ?licenseBackMediaId,
        '''aadharNumber''': ?aadharNumber,
        '''aadharFrontMediaId''': ?aadharFrontMediaId,
        '''aadharBackMediaId''': ?aadharBackMediaId,
        '''panNumber''': ?panNumber,
        '''panFrontMediaId''': ?panFrontMediaId,
        '''panBackMediaId''': ?panBackMediaId,
      },
    );

    if (response is Map<String, dynamic> && response['''success'''] == true) {
      return;
    }
    throw const ServerException('''Failed to submit KYC verification.''');
  }
}
