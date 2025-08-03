import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/service_model.dart';
import '../database/database_service.dart';

class DataLoaderService {
  final DatabaseService _databaseService;

  DataLoaderService(this._databaseService);

  /// Load sample services from JSON file into the database
  Future<void> loadSampleData() async {
    try {
      // Check if data is already loaded
      final existingServices = await _databaseService.getAllServices();
      if (existingServices.isNotEmpty) {
        print('Sample data already loaded');
        return;
      }

      // Load JSON file
      final String jsonString = await rootBundle.loadString('assets/data/sample_services.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Parse services
      final List<dynamic> servicesJson = jsonData['services'];
      final List<ServiceModel> services = servicesJson
          .map((json) => ServiceModel.fromJson(json))
          .toList();

      // Insert into database
      await _databaseService.insertServices(services);
      
      print('Successfully loaded ${services.length} sample services');
    } catch (e) {
      print('Error loading sample data: $e');
    }
  }

  /// Load additional services from a remote API (for future implementation)
  Future<void> loadRemoteServices() async {
    // TODO: Implement API call to load services from your backend
    // This would typically call your Flask backend to get updated service data
  }

  /// Clear all data and reload sample data
  Future<void> resetToSampleData() async {
    await _databaseService.clearAllData();
    await loadSampleData();
  }
}
