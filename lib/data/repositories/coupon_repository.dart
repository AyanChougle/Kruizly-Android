import '''../../core/constants/api_endpoints.dart''';
import '''../../core/errors/app_exceptions.dart''';
import '''../../core/network/api_client.dart''';
import '''../models/coupon_model.dart''';

class CouponRepository {
  final ApiClient _apiClient;

  CouponRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<CouponValidationResult> validateCoupon(String code, double orderTotal) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.validateCoupon,
        data: {
          '''code''': code.trim().toUpperCase(),
          '''orderTotal''': orderTotal,
        },
      );

      if (response is Map<String, dynamic>) {
        return CouponValidationResult.fromJson(response);
      }
      throw const ServerException('''Invalid coupon response from server.''');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<CouponModel>> getActiveCoupons({bool includeAll = true}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.coupons,
        queryParameters: includeAll ? {'all': 1} : null,
      );
      if (response is Map<String, dynamic> && response['coupons'] is List) {
        return (response['coupons'] as List)
            .map((c) => CouponModel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
