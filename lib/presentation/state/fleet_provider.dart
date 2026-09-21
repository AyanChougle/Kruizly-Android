import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vehicle_model.dart';
import 'app_providers.dart';

class FleetState {
  final bool isLoading;
  final List<VehicleModel> allVehicles;
  final String selectedCategory;
  final String selectedTransmission;
  final String searchQuery;
  final String sortBy; // "price_asc", "price_desc", "name"
  final String? errorMessage;

  const FleetState({
    this.isLoading = false,
    this.allVehicles = const [],
    this.selectedCategory = 'all',
    this.selectedTransmission = 'all',
    this.searchQuery = '',
    this.sortBy = 'recommended',
    this.errorMessage,
  });

  List<VehicleModel> get vehicles => allVehicles;

  List<VehicleModel> get filteredVehicles {
    final list = allVehicles.where((v) {
      if (selectedCategory != 'all' && v.category.toLowerCase() != selectedCategory.toLowerCase()) {
        return false;
      }
      if (selectedTransmission != 'all' && v.transmission.toLowerCase() != selectedTransmission.toLowerCase()) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchName = v.fullName.toLowerCase().contains(query);
        final matchBrand = v.brand.toLowerCase().contains(query);
        final matchCategory = v.category.toLowerCase().contains(query);
        final matchFuel = v.fuel.toLowerCase().contains(query);
        if (!matchName && !matchBrand && !matchCategory && !matchFuel) {
          return false;
        }
      }
      return true;
    }).toList();

    if (sortBy == 'price_desc') {
      list.sort((a, b) => b.priceDay.compareTo(a.priceDay));
    } else if (sortBy == 'price_asc') {
      list.sort((a, b) => a.priceDay.compareTo(b.priceDay));
    } else if (sortBy == 'name') {
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else {
      // 'recommended' - Available vehicles first, then popular/highest tier
      list.sort((a, b) {
        if (a.isAvailable != b.isAvailable) {
          return a.isAvailable ? -1 : 1;
        }
        return b.priceDay.compareTo(a.priceDay);
      });
    }

    return list;
  }

  FleetState copyWith({
    bool? isLoading,
    List<VehicleModel>? allVehicles,
    String? selectedCategory,
    String? selectedTransmission,
    String? searchQuery,
    String? sortBy,
    String? errorMessage,
  }) {
    return FleetState(
      isLoading: isLoading ?? this.isLoading,
      allVehicles: allVehicles ?? this.allVehicles,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedTransmission: selectedTransmission ?? this.selectedTransmission,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      errorMessage: errorMessage,
    );
  }
}

class FleetNotifier extends StateNotifier<FleetState> {
  final Ref _ref;

  FleetNotifier(this._ref) : super(const FleetState(isLoading: true)) {
    fetchFleet();
  }

  Future<void> fetchFleet() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final vehicles = await _ref.read(fleetRepositoryProvider).getVehicles();
      state = state.copyWith(isLoading: false, allVehicles: vehicles);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setTransmission(String transmission) {
    state = state.copyWith(selectedTransmission: transmission);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  Future<void> updateVehicle({
    required int vehicleId,
    double? priceDay,
    double? priceHour,
    bool? isAvailable,
  }) async {
    final updatedList = state.allVehicles.map((v) {
      if (v.id == vehicleId) {
        return v.copyWith(
          priceDay: priceDay ?? v.priceDay,
          priceHour: priceHour ?? v.priceHour,
          isAvailable: isAvailable ?? v.isAvailable,
          status: isAvailable != null ? (isAvailable ? 'available' : 'rented') : v.status,
        );
      }
      return v;
    }).toList();

    state = state.copyWith(allVehicles: updatedList);

    try {
      final repo = _ref.read(adminRepositoryProvider);
      await repo.updateVehicle(
        vehicleId: vehicleId,
        priceDay: priceDay,
        priceHour: priceHour,
        isAvailable: isAvailable,
      );
    } catch (_) {}
  }
}

final fleetProvider = StateNotifierProvider<FleetNotifier, FleetState>((ref) {
  return FleetNotifier(ref);
});

final activeFleetProvider = FutureProvider<List<VehicleModel>>((ref) async {
  return await ref.watch(fleetRepositoryProvider).getActiveFleet();
});

final vehicleDetailProvider = FutureProvider.family<VehicleModel?, String>((ref, id) async {
  final fleet = ref.watch(fleetProvider);
  // First check in-memory fleet for immediate responsiveness
  final existing = fleet.allVehicles.where((v) => v.id.toString() == id || v.regNo == id).firstOrNull;
  if (existing != null) return existing;
  return await ref.watch(fleetRepositoryProvider).getVehicleDetail(id);
});
