import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Model for a Place
class PlaceResult {
  final String placeId;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String phone;
  final String website;
  final String address;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.phone = '',
    this.website = '',
    this.address = '',
  });

  PlaceResult copyWith({
    String? phone,
    String? website,
    String? address,
  }) {
    return PlaceResult(
      placeId: placeId,
      name: name,
      type: type,
      lat: lat,
      lng: lng,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
    );
  }
}

class PlacesService {
  static final _apiKey = dotenv.env['MAPS_API_KEY'];

  // Map your keywords to Google supported types
  static const Map<String, String> typeMap = {
    'shelter': 'lodging',
    'clinic': 'doctor',
    'food': 'food',
    'mental_health': 'health', // Google Places type for mental health resources
    'food bank': 'grocery_or_supermarket',
  };

  // Fetch nearby places
  static Future<List<PlaceResult>> fetchNearby({
    required double lat,
    required double lng,
    required String keyword, // 'shelter', 'clinic', etc.
  }) async {
    final type = typeMap[keyword.toLowerCase()] ?? '';
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=2000' // 2 km
        '${type.isNotEmpty ? '&type=$type' : ''}'
        '&keyword=${Uri.encodeComponent(keyword)}'
        '&key=$_apiKey';

    debugPrint('Fetching $keyword (type=$type)');

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final data = json.decode(res.body) as Map<String, dynamic>;

      if (res.statusCode != 200 || data['status'] != 'OK') {
        debugPrint('Places API error: ${data['status']}');
        return [];
      }

      final rawResults = data['results'];
      if (rawResults == null || rawResults is! List) return [];

      final List<PlaceResult> results = [];
      for (final p in rawResults) {
        if (p is! Map<String, dynamic>) continue;
        try {
          final geo = p['geometry'] as Map<String, dynamic>?;
          final loc = geo?['location'] as Map<String, dynamic>?;
          if (loc == null) continue;
          // Prefer formatted_address, fallback to vicinity, else empty
          String address = '';
          if (p['formatted_address'] != null &&
              p['formatted_address'].toString().isNotEmpty) {
            address = p['formatted_address'];
          } else if (p['vicinity'] != null &&
              p['vicinity'].toString().isNotEmpty) {
            address = p['vicinity'];
          }
          final place = PlaceResult(
            placeId: p['place_id'] as String? ?? '',
            name: p['name'] as String? ?? 'Unknown',
            lat: (loc['lat'] as num?)?.toDouble() ?? 0.0,
            lng: (loc['lng'] as num?)?.toDouble() ?? 0.0,
            type: keyword,
            address: address,
          );
          results.add(place);
        } catch (e) {
          debugPrint('Skip place parse error: $e');
        }
      }

      debugPrint('Fetched ${results.length} $keyword places');
      return results;
    } catch (e) {
      debugPrint('Places fetchNearby error: $e');
      return [];
    }
  }

  // Fetch details like phone, website, address
  static Future<PlaceResult> fetchDetails(PlaceResult place) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${place.placeId}'
        '&fields=name,formatted_address,formatted_phone_number,website'
        '&key=$_apiKey';

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      final data = json.decode(res.body) as Map<String, dynamic>;

      if (res.statusCode != 200 || data['status'] != 'OK') {
        debugPrint('Details API error for ${place.name}: ${data['status']}');
        return place;
      }

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return place;

      return place.copyWith(
        phone: result['formatted_phone_number'] as String? ?? '',
        website: result['website'] as String? ?? '',
        address: result['formatted_address'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('Details error for ${place.name}: $e');
      return place;
    }
  }
}
