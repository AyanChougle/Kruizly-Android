import '''../../core/constants/api_endpoints.dart''';
import '''../../core/network/api_client.dart''';
import '''../models/vehicle_model.dart''';

class FleetRepository {
  final ApiClient _apiClient;

  FleetRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<VehicleModel>> getVehicles({
    String? category,
    bool? availableOnly,
  }) async {
    final Map<String, dynamic> params = {};
    if (category != null && category != '''all''') {
      params['''category'''] = category;
    }
    if (availableOnly == true) {
      params['''available'''] = 1;
    }

    final response = await _apiClient.get(
      ApiEndpoints.vehicles,
      queryParameters: params.isNotEmpty ? params : null,
    );

    if (response is Map<String, dynamic> && response['''vehicles'''] is List) {
      return (response['''vehicles'''] as List)
          .map((v) => VehicleModel.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static const List<Map<String, dynamic>> defaultActive9Fleets = [
    {
      'id': 18,
      'carId': 'CRP-033',
      'regNo': 'MH03EL1025',
      'brand': 'Maruti Suzuki',
      'model': 'Fronx',
      'year': 2025,
      'category': 'economy',
      'transmission': 'Automatic',
      'fuel': 'Petrol',
      'seats': 5,
      'priceDay': 2700,
      'priceHour': 112.5,
      'hub': 'Gavson Business Park, Ghansoli',
      'acquisitionType': 'Partner',
      'ownerName': 'Aditi Lotankar',
      'acquisitionDate': '2026-07-20',
      'available': 1,
      'status': 'available',
      'imageUrl': 'assets/fleet/Maruti Suzuki Fronx.png',
      'isActiveFleet': true,
    },
    {
      'id': 14,
      'carId': 'CRP-034',
      'regNo': 'MH05GJ4711',
      'brand': 'Maruti Suzuki',
      'model': 'Ertiga',
      'year': 2026,
      'category': 'mpv',
      'transmission': 'Manual',
      'fuel': 'Petrol + CNG',
      'seats': 7,
      'priceDay': 3300,
      'priceHour': 137.5,
      'hub': 'Gavson Business Park, Ghansoli',
      'acquisitionType': 'Partner',
      'ownerName': 'Viren Gupta',
      'acquisitionDate': '2026-07-24',
      'available': 1,
      'status': 'available',
      'imageUrl': 'assets/fleet/Maruti Suzuki Ertiga.png',
      'isActiveFleet': true,
    },
    {
      'id': 20,
      'carId': 'CRP-035',
      'regNo': 'MH48GJ4153',
      'brand': 'Toyota',
      'model': 'Glanza',
      'year': 2025,
      'category': 'economy',
      'transmission': 'Manual',
      'fuel': 'Petrol + CNG',
      'seats': 5,
      'priceDay': 2600,
      'priceHour': 108.33,
      'hub': 'Gavson Business Park, Ghansoli',
      'acquisitionType': 'Partner',
      'ownerName': 'Ajay Vishwakarma',
      'acquisitionDate': '2026-07-29',
      'available': 1,
      'status': 'available',
      'imageUrl': 'assets/fleet/Toyota Glanza.png',
      'isActiveFleet': true,
    },
    {
      'id': 19,
      'carId': 'CRP-036',
      'regNo': 'MH04MU1178',
      'brand': 'Toyota',
      'model': 'Glanza',
      'year': 2025,
      'category': 'economy',
      'transmission': 'Manual',
      'fuel': 'Petrol + CNG',
      'seats': 5,
      'priceDay': 2600,
      'priceHour': 108.33,
      'hub': 'Gavson Business Park, Ghansoli',
      'acquisitionType': 'Partner',
      'ownerName': 'Kundan Singh',
      'acquisitionDate': '2026-08-04',
      'available': 1,
      'status': 'available',
      'imageUrl': 'assets/fleet/Toyota Glanza.png',
      'isActiveFleet': true,
    },
    {
      'id': 28,
      'carId': 'CRP-037',
      'regNo': 'MH05FV3454',
      'brand': 'Tata',
      'model': 'Punch',
      'year': 2025,
      'category': 'suv',
      'transmission': 'Manual',
      'fuel': 'Petrol + CNG',
      'seats': 5,
      'priceDay': 2700,
      'priceHour': 112.5,
      'hub': 'Gavson Business Park, Ghansoli',
      'acquisitionType': 'Partner',
      'ownerName': 'Tai Phad',
      'acquisitionDate': '2026-08-13',
      'available': 1,
      'status': 'available',
      'imageUrl': 'assets/fleet/Tata Punch.png',
      'isActiveFleet': true,
    },
    {
      'id': 17,
      'carId': 'CRP-038',
      'regNo': 'MH43CU1632',
      'brand': 'Maruti Suzuki',
      'model': 'Fronx',
      'year': 2025,
      'category': 'economy',
      'transmission': 'Manual',
      'fuel': 'Petrol + CNG',
      'seats': 5,
      'priceDay': 2600,
      'priceHour': 108.33,
      'hub': 'Gavson Business Park, Ghansoli',
      'acquisitionType': 'Partner',
      'ownerName': 'Amol Gole',
      'acquisitionDate': '2026-08-19',
      'available': 1,
      'status': 'available',
      'imageUrl': 'assets/fleet/Maruti Suzuki Fronx.png',
      'isActiveFleet': true,
    },
    {
      'id': 38,
      'carId': 'CRP-039',
      'regNo': 'MH02FU6808',
      'brand': 'Mahindra',
      'model': 'XUV700',
      'year': 2026,
      'category': 'suv',
      'transmission': 'Automatic',
      'fuel': 'Petrol',
      'seats': 5,
      'priceDay': 6500,
      'priceHour': 270.83,
      'hub': 'Gavson Business Park, Ghansoli',
      'acquisitionType': 'Partner',
      'ownerName': 'Saif Feroz Shaikh',
      'acquisitionDate': '2026-08-01',
      'available': 1,
      'status': 'available',
      'imageUrl': 'assets/fleet/Mahindra XUV 700.png',
      'isActiveFleet': true,
    },
    {
      'id': 7,
      'carId': 'CPR-007',
      'regNo': '24BH3375A',
      'brand': 'Maruti Suzuki',
      'model': 'Baleno',
      'year': 2024,
      'category': 'economy',
      'transmission': 'Manual',
      'fuel': 'Petrol',
      'seats': 5,
      'priceDay': 2500,
      'priceHour': 104.17,
      'hub': 'Gavson Business Park, Ghansoli',
      'acquisitionType': 'Fleet Catalog',
      'ownerName': 'Kruizly Fleet Host',
      'acquisitionDate': '2026-01-01',
      'available': 1,
      'status': 'available',
      'imageUrl': 'assets/fleet/Maruti Suzuki Baleno.png',
      'isActiveFleet': true,
    },
    {
      'id': 39,
      'carId': 'CPR-032',
      'regNo': 'MH43BY2773',
      'brand': 'MG',
      'model': 'Hector',
      'year': 2021,
      'category': 'suv',
      'transmission': 'Automatic',
      'fuel': 'Petrol',
      'seats': 6,
      'priceDay': 5500,
      'priceHour': 229.0,
      'hub': 'Gavson Business Park, Ghansoli',
      'acquisitionType': 'Partner',
      'ownerName': 'Anil Kumar Gupta',
      'acquisitionDate': '2026-09-13',
      'available': 1,
      'status': 'available',
      'imageUrl': 'assets/fleet/MG Hector.png',
      'isActiveFleet': true,
    },
  ];

  Future<List<VehicleModel>> getActiveFleet() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.activeFleet);
      if (response is Map<String, dynamic> && response['activeFleet'] is List) {
        final list = (response['activeFleet'] as List)
            .map((v) => VehicleModel.fromJson(v as Map<String, dynamic>))
            .where(
              (v) =>
                  !v.regNo.toUpperCase().contains('ZIP') && v.regNo.isNotEmpty,
            )
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return defaultActive9Fleets.map((v) => VehicleModel.fromJson(v)).toList();
  }

  Future<VehicleModel?> getVehicleDetail(String regNo) async {
    final response = await _apiClient.get(
      ApiEndpoints.vehicleDetail,
      queryParameters: {'''regNo''': regNo},
    );

    if (response is Map<String, dynamic> && response['''vehicle'''] != null) {
      return VehicleModel.fromJson(
        response['''vehicle'''] as Map<String, dynamic>,
      );
    }
    return null;
  }
}
