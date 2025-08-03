import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/service_model.dart';
import '../../../core/models/search_request_model.dart';
import 'help_search_state.dart';

class HelpSearchCubit extends Cubit<HelpSearchState> {
  final AIService _aiService;
  final LocationService _locationService;
  final DatabaseService _databaseService;

  HelpSearchCubit({
    required AIService aiService,
    required LocationService locationService,
    required DatabaseService databaseService,
  })  : _aiService = aiService,
        _locationService = locationService,
        _databaseService = databaseService,
        super(const HelpSearchState.initial());

  /// Process user input and search for relevant services
  Future<void> searchForHelp(String userInput) async {
    if (userInput.trim().isEmpty) return;

    emit(const HelpSearchState.loading());

    try {
      // Get user location
      Position? position = await _locationService.getCurrentLocation();
      
      // Process input through AI
      final aiResult = await _aiService.processUserInput(userInput);
      
      // Convert detected categories to ServiceCategory enums
      List<ServiceCategory> categories = aiResult.detectedCategories
          .map((cat) => _stringToServiceCategory(cat))
          .where((cat) => cat != null)
          .cast<ServiceCategory>()
          .toList();

      // Search database for matching services
      List<ServiceModel> services = await _databaseService.searchServices(
        categories: categories.map((c) => c.name).toList(),
        latitude: position?.latitude,
        longitude: position?.longitude,
        isEmergency: aiResult.isEmergency,
        limit: 20,
      );

      // Sort by distance if location is available
      if (position != null) {
        services = _sortServicesByDistance(services, position);
      }

      final response = SearchResponseModel(
        services: services,
        detectedCategories: categories,
        interpretedIntent: aiResult.interpretedIntent,
        usedOfflineMode: aiResult.usedOfflineMode,
      );

      if (services.isEmpty) {
        emit(HelpSearchState.noResults(
          searchQuery: userInput,
          interpretedIntent: aiResult.interpretedIntent,
        ));
      } else {
        emit(HelpSearchState.success(response));
      }
    } catch (error) {
      emit(HelpSearchState.error(error.toString()));
    }
  }

  /// Search specifically for emergency services
  Future<void> searchEmergencyServices() async {
    emit(const HelpSearchState.loading());

    try {
      Position? position = await _locationService.getCurrentLocation();
      
      List<ServiceModel> emergencyServices = await _databaseService.searchServices(
        isEmergency: true,
        latitude: position?.latitude,
        longitude: position?.longitude,
        limit: 10,
      );

      if (position != null) {
        emergencyServices = _sortServicesByDistance(emergencyServices, position);
      }

      final response = SearchResponseModel(
        services: emergencyServices,
        detectedCategories: [ServiceCategory.emergency],
        interpretedIntent: 'Emergency services needed',
        usedOfflineMode: false,
      );

      emit(HelpSearchState.success(response));
    } catch (error) {
      emit(HelpSearchState.error(error.toString()));
    }
  }

  /// Clear search results
  void clearSearch() {
    emit(const HelpSearchState.initial());
  }

  /// Helper method to convert string to ServiceCategory
  ServiceCategory? _stringToServiceCategory(String categoryString) {
    switch (categoryString.toLowerCase()) {
      case 'food':
        return ServiceCategory.food;
      case 'shelter':
        return ServiceCategory.shelter;
      case 'healthcare':
        return ServiceCategory.healthcare;
      case 'mentalhealth':
        return ServiceCategory.mentalHealth;
      case 'employment':
        return ServiceCategory.employment;
      case 'financial':
        return ServiceCategory.financial;
      case 'legal':
        return ServiceCategory.legal;
      case 'childcare':
        return ServiceCategory.childcare;
      case 'education':
        return ServiceCategory.education;
      case 'transportation':
        return ServiceCategory.transportation;
      case 'utilities':
        return ServiceCategory.utilities;
      case 'clothing':
        return ServiceCategory.clothing;
      case 'emergency':
        return ServiceCategory.emergency;
      default:
        return null;
    }
  }

  /// Sort services by distance from user location
  List<ServiceModel> _sortServicesByDistance(
    List<ServiceModel> services,
    Position userPosition,
  ) {
    services.sort((a, b) {
      if (a.address.latitude == null || a.address.longitude == null) return 1;
      if (b.address.latitude == null || b.address.longitude == null) return -1;

      double distanceA = _locationService.calculateDistanceInMiles(
        userPosition.latitude,
        userPosition.longitude,
        a.address.latitude!,
        a.address.longitude!,
      );

      double distanceB = _locationService.calculateDistanceInMiles(
        userPosition.latitude,
        userPosition.longitude,
        b.address.latitude!,
        b.address.longitude!,
      );

      return distanceA.compareTo(distanceB);
    });

    return services;
  }
}
