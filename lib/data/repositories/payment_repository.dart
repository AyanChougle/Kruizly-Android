import '''dart:io''';
import '''package:dio/dio.dart''';
import '''../../core/constants/api_endpoints.dart''';
import '''../../core/errors/app_exceptions.dart''';
import '''../../core/network/api_client.dart''';
import '''../models/payment_model.dart''';

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> uploadPaymentScreenshot(
    File file,
    String bookingId,
  ) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      '''file''': await MultipartFile.fromFile(file.path, filename: fileName),
      '''category''': '''payment_proof''',
      '''relatedId''': bookingId,
    });

    final response = await _apiClient.uploadFile(
      ApiEndpoints.uploadMedia,
      formData: formData,
    );
    if (response is Map<String, dynamic> && response['''success'''] == true) {
      return {
        '''mediaId''': response['''mediaId'''] ?? response['''id'''],
        '''url''': response['''url'''] ?? response['''mediaUrl'''],
      };
    }
    throw const ServerException('''Failed to upload payment screenshot.''');
  }

  Future<String> submitPayment({
    required String bookingId,
    required double amount,
    required String utr,
    String method = '''upi''',
    String? screenshotUrl,
    String? screenshotMediaId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.submitPayment,
      data: {
        '''bookingId''': bookingId,
        '''amount''': amount,
        '''method''': method,
        '''utr''': utr,
        '''transactionReference''': utr,
        '''screenshotUrl''': ?screenshotUrl,
        '''screenshotMediaId''': ?screenshotMediaId,
      },
    );

    if (response is Map<String, dynamic> && response['''success'''] == true) {
      return (response['''paymentId'''] ?? '''''').toString();
    }
    throw const ServerException('''Failed to record payment submission.''');
  }

  Future<List<PaymentModel>> getMyPayments() async {
    final response = await _apiClient.get(ApiEndpoints.payments);
    if (response is Map<String, dynamic> && response['''payments'''] is List) {
      return (response['''payments'''] as List)
          .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
