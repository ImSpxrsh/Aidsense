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
  final String openingHours;
  final bool openNow;
  final bool walkIn;
  final bool appointmentRequired;
  final bool idRequired;
  final String cost;
  final bool familiesWelcome;
  final bool womenOnly;
  final bool youthFriendly;
  final String phone;
  final String website;
  final String address;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.openingHours = '',
    this.openNow = false,
    this.walkIn = false,
    this.appointmentRequired = false,
    this.idRequired = false,
    this.cost = 'unknown',
    this.familiesWelcome = false,
    this.womenOnly = false,
    this.youthFriendly = false,
    this.phone = '',
    this.website = '',
    this.address = '',
  });

  PlaceResult copyWith({
    String? openingHours,
    bool? openNow,
    bool? walkIn,
    bool? appointmentRequired,
    bool? idRequired,
    String? cost,
    bool? familiesWelcome,
    bool? womenOnly,
    bool? youthFriendly,
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
      openingHours: openingHours ?? this.openingHours,
      openNow: openNow ?? this.openNow,
      walkIn: walkIn ?? this.walkIn,
      appointmentRequired: appointmentRequired ?? this.appointmentRequired,
      idRequired: idRequired ?? this.idRequired,
      cost: cost ?? this.cost,
      familiesWelcome: familiesWelcome ?? this.familiesWelcome,
      womenOnly: womenOnly ?? this.womenOnly,
      youthFriendly: youthFriendly ?? this.youthFriendly,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
    );
  }
}

class _EligibilityProfile {
  final bool walkIn;
  final bool appointmentRequired;
  final bool idRequired;
  final String cost;
  final bool familiesWelcome;
  final bool womenOnly;
  final bool youthFriendly;

  const _EligibilityProfile({
    required this.walkIn,
    required this.appointmentRequired,
    required this.idRequired,
    required this.cost,
    required this.familiesWelcome,
    required this.womenOnly,
    required this.youthFriendly,
  });
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
        '&fields=name,formatted_address,formatted_phone_number,website,opening_hours,current_opening_hours'
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

      final hours = _extractOpeningHours(result);
      final profile = await _inferEligibility(place: place, details: result);

      return place.copyWith(
        openingHours: hours,
        openNow: _extractOpenNow(result),
        walkIn: profile.walkIn,
        appointmentRequired: profile.appointmentRequired,
        idRequired: profile.idRequired,
        cost: profile.cost,
        familiesWelcome: profile.familiesWelcome,
        womenOnly: profile.womenOnly,
        youthFriendly: profile.youthFriendly,
        phone: result['formatted_phone_number'] as String? ?? '',
        website: result['website'] as String? ?? '',
        address: result['formatted_address'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('Details error for ${place.name}: $e');
      return place;
    }
  }

  static String _extractOpeningHours(Map<String, dynamic> details) {
    final currentHours = details['current_opening_hours'];
    final openingHours = details['opening_hours'];

    final fromCurrent = _weekdayTextToString(currentHours);
    if (fromCurrent.isNotEmpty) return fromCurrent;

    final fromOpening = _weekdayTextToString(openingHours);
    if (fromOpening.isNotEmpty) return fromOpening;

    return '';
  }

  static bool _extractOpenNow(Map<String, dynamic> details) {
    final currentHours = details['current_opening_hours'];
    final openingHours = details['opening_hours'];

    bool? fromCurrent;
    if (currentHours is Map<String, dynamic>) {
      final value = currentHours['open_now'];
      if (value is bool) fromCurrent = value;
    }
    if (fromCurrent != null) return fromCurrent;

    if (openingHours is Map<String, dynamic>) {
      final value = openingHours['open_now'];
      if (value is bool) return value;
    }
    return false;
  }

  static String _weekdayTextToString(dynamic value) {
    if (value is! Map<String, dynamic>) return '';
    final weekdayText = value['weekday_text'];
    if (weekdayText is! List) return '';

    final lines = weekdayText
        .where((line) => line != null)
        .map((line) => line.toString().trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return lines.join('\n');
  }

  static Future<_EligibilityProfile> _inferEligibility({
    required PlaceResult place,
    required Map<String, dynamic> details,
  }) async {
    final heuristic = _heuristicEligibility(place, details);
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) return heuristic;

    final prompt = {
      'task': 'Infer likely barrier/eligibility flags for an aid resource.',
      'rules': [
        'Use conservative defaults when unknown.',
        'Return JSON only.',
        'cost must be one of: free, low-cost, paid, unknown.',
      ],
      'resource': {
        'name': place.name,
        'type': place.type,
        'address': details['formatted_address']?.toString() ?? place.address,
        'website': details['website']?.toString() ?? '',
        'opening_hours': _extractOpeningHours(details),
      },
      'expected_schema': {
        'walk_in': 'bool',
        'appointment_required': 'bool',
        'id_required': 'bool',
        'cost': 'free | low-cost | paid | unknown',
        'families_welcome': 'bool',
        'women_only': 'bool',
        'youth_friendly': 'bool'
      }
    };

    final body = jsonEncode({
      'model': 'gpt-5',
      'temperature': 0.1,
      'max_completion_tokens': 180,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You infer practical aid-resource eligibility flags from limited metadata. Return only valid JSON.'
        },
        {'role': 'user', 'content': jsonEncode(prompt)}
      ]
    });

    try {
      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return heuristic;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) return heuristic;
      final content = choices.first['message']?['content']?.toString();
      if (content == null || content.trim().isEmpty) return heuristic;

      final parsed = jsonDecode(_stripJsonFences(content.trim()));
      if (parsed is! Map<String, dynamic>) return heuristic;

      final rawCost = (parsed['cost'] ?? heuristic.cost).toString();
      final safeCost = _normalizeCost(rawCost);

      return _EligibilityProfile(
        walkIn: _asBool(parsed['walk_in'], heuristic.walkIn),
        appointmentRequired: _asBool(
            parsed['appointment_required'], heuristic.appointmentRequired),
        idRequired: _asBool(parsed['id_required'], heuristic.idRequired),
        cost: safeCost,
        familiesWelcome:
            _asBool(parsed['families_welcome'], heuristic.familiesWelcome),
        womenOnly: _asBool(parsed['women_only'], heuristic.womenOnly),
        youthFriendly:
            _asBool(parsed['youth_friendly'], heuristic.youthFriendly),
      );
    } catch (_) {
      return heuristic;
    }
  }

  static _EligibilityProfile _heuristicEligibility(
      PlaceResult place, Map<String, dynamic> details) {
    final text =
        '${place.name} ${place.type} ${place.address} ${details['website'] ?? ''} ${_extractOpeningHours(details)}'
            .toLowerCase();

    final walkIn = text.contains('walk in') ||
        text.contains('walk-in') ||
        text.contains('drop in');
    final appointmentRequired = text.contains('appointment') ||
        text.contains('book') ||
        text.contains('schedule');
    final idRequired = text.contains('id required') ||
        text.contains('photo id') ||
        text.contains('documentation required');

    final familiesWelcome =
        text.contains('family') || text.contains('families');
    final womenOnly = text.contains('women only') || text.contains('for women');
    final youthFriendly = text.contains('youth') ||
        text.contains('teen') ||
        text.contains('young adult');

    var cost = 'unknown';
    if (text.contains('free')) {
      cost = 'free';
    } else if (text.contains('low cost') || text.contains('sliding scale')) {
      cost = 'low-cost';
    } else if (text.contains('paid') || text.contains('fee')) {
      cost = 'paid';
    }

    return _EligibilityProfile(
      walkIn: walkIn,
      appointmentRequired: appointmentRequired,
      idRequired: idRequired,
      cost: cost,
      familiesWelcome: familiesWelcome,
      womenOnly: womenOnly,
      youthFriendly: youthFriendly,
    );
  }

  static String _stripJsonFences(String content) {
    var out = content;
    if (out.startsWith('```')) {
      out = out.replaceFirst(RegExp(r'^```json\\s*'), '');
      out = out.replaceFirst(RegExp(r'^```\\s*'), '');
      out = out.replaceFirst(RegExp(r'```$'), '').trim();
    }
    return out;
  }

  static bool _asBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'true') return true;
      if (v == 'false') return false;
    }
    return fallback;
  }

  static String _normalizeCost(String raw) {
    final cost = raw.toLowerCase().trim();
    switch (cost) {
      case 'free':
        return 'free';
      case 'low-cost':
      case 'low cost':
        return 'low-cost';
      case 'paid':
        return 'paid';
      default:
        return 'unknown';
    }
  }
}
