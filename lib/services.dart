import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class ResourceService {
  final SupabaseClient client;
  ResourceService({SupabaseClient? instance})
      : client = instance ?? Supabase.instance.client;

  Stream<List<Resource>> watchResources() {
    try {
      return client.from('resources').stream(primaryKey: ['id']).map((data) =>
          data.map((d) => Resource.fromMap(d['id'], d)).toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  Future<List<Resource>> fetchResourcesOnce() async {
    try {
      final response = await client.from('resources').select();
      return (response as List<dynamic>).map((d) => Resource.fromMap(d['id'], d as Map<String, dynamic>)).toList();
    } catch (_) {
      return []; // return empty list if Supabase fails
    }
  }
}

// final List<Resource> sampleResources = [
//   Resource(
//     id: 'r1',
//     name: 'St. Mark Emergency Shelter',
//     type: 'shelter',
//     address: '123 Market St, NYC',
//     latitude: 40.7128,
//     longitude: -74.0060,
//     tags: ['24/7', 'Women', 'Homeless'],
//     phone: '+1 212-555-0100',
//     website: 'https://example.com/shelter',
//   ),
//   Resource(
//     id: 'r2',
//     name: 'Food Bank for NYC',
//     type: 'food',
//     address: '55 Broadway, NYC',
//     latitude: 40.7099,
//     longitude: -74.0131,
//     tags: ['Food', 'Open 9-5'],
//     phone: '+1 212-555-0123',
//     website: 'https://example.com/food',
//   ),
//   Resource(
//     id: 'r3',
//     name: 'MediCure Pharmacy',
//     type: 'pharmacy',
//     address: '100 Main St, Newark, NJ',
//     latitude: 40.7357,
//     longitude: -74.1724,
//     tags: ['Pharmacy'],
//     phone: '+1 973-555-0199',
//     website: 'https://example.com/pharmacy',
//   ),
// ];
