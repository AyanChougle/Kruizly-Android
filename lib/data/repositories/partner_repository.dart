import '''dart:io''';
import '''package:dio/dio.dart''';
import '''../../core/constants/api_endpoints.dart''';
import '''../../core/errors/app_exceptions.dart''';
import '''../../core/network/api_client.dart''';
import '''../models/partner_car_model.dart''';

class PartnerRepository {
  final ApiClient _apiClient;

  PartnerRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<PartnerCarModel>> getMyPartnerCars() async {
    final response = await _apiClient.get(ApiEndpoints.partnerCars);
    if (response is Map<String, dynamic> && response['''partnerCars'''] is List) {
      return (response['''partnerCars'''] as List)
          .map((c) => PartnerCarModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<String> uploadCarPhoto(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      '''file''': await MultipartFile.fromFile(file.path, filename: fileName),
      '''category''': '''vehicle_gallery''',
    });

    final response = await _apiClient.uploadFile(ApiEndpoints.uploadMedia, formData: formData);
    if (response is Map<String, dynamic> && response['''success'''] == true) {
      return (response['''url'''] ?? response['''mediaUrl'''] ?? '''''').toString();
    }
    throw const ServerException('''Failed to upload car photo.''');
  }

  Future<String> submitPartnerCar({
    required String brand,
    required String model,
    required int year,
    required String regNo,
    required String transmission,
    required String fuel,
    required String city,
    required double expectedPrice,
    required List<String> photos,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.partnerCars,
      data: {
        '''brand''': brand,
        '''model''': model,
        '''year''': year,
        '''regNo''': regNo,
        '''transmission''': transmission,
        '''fuel''': fuel,
        '''city''': city,
        '''expectedPrice''': expectedPrice,
        '''photos''': photos,
      },
    );

    if (response is Map<String, dynamic> && response['''success'''] == true) {
      return (response['''carId'''] ?? '''''').toString();
    }
    throw const ServerException('''Failed to submit vehicle listing.''');
  }
}
