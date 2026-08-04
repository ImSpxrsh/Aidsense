import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Cache result container
class CachedResult {
  final List<PlaceResult> results;
  final DateTime expiresAt;

  CachedResult({required this.results, required this.expiresAt});
}

// Simple cache for nearby search results
class _SearchCache {
  static final Map<String, CachedResult> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 20);

  static CachedResult? get(String key) {
    final item = _cache[key];
    if (item == null) return null;
    if (DateTime.now().isAfter(item.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    debugPrint('[CACHE] HIT for $key');
    return item;
  }

  static void set(String key, List<PlaceResult> results) {
    _cache[key] = CachedResult(
      results: results,
      expiresAt: DateTime.now().add(_cacheDuration),
    );
    debugPrint('[CACHE] SET $key (expires in 20min)');
  }
}

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
  static const double _radiusMeters = 2000;
  static final bool _supabaseFallbackEnabled =
      (dotenv.env['ENABLE_SUPABASE_FALLBACK'] ?? 'false').toLowerCase() ==
          'true';
  static final bool _aiEnrichmentEnabled =
      (dotenv.env['ENABLE_AI_ENRICHMENT'] ?? 'false').toLowerCase() == 'true';
  static final bool _googleDetailsEnabled =
      (dotenv.env['ENABLE_GOOGLE_DETAILS'] ?? 'true').toLowerCase() == 'true';

  // Map your keywords to Google supported types
  static const Map<String, String> typeMap = {
    'shelter': 'lodging',
    'clinic': 'doctor',
    'food': 'food',
    'mental_health': 'health', // Google Places type for mental health resources
    'food bank': 'grocery_or_supermarket',
  };

  // Fetch nearby places WITH CACHING
  static Future<List<PlaceResult>> fetchNearby({
    required double lat,
    required double lng,
    required String keyword,
  }) async {
    // Check cache first
    final cacheKey =
        '${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}_$keyword';
    final cached = _SearchCache.get(cacheKey);
    if (cached != null) return cached.results;

    // Google-first search for higher data quality with cache + lazy details.
    final googleResults = await _fetchNearbyFromAPI(
      lat: lat,
      lng: lng,
      keyword: keyword,
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      debugPrint('Google nearby timed out for "$keyword"');
      return const <PlaceResult>[];
    });
    if (googleResults.isNotEmpty) {
      _SearchCache.set(cacheKey, googleResults);
      return googleResults;
    }

    if (!_supabaseFallbackEnabled) {
      debugPrint(
          'Google returned no resources for "$keyword" and Supabase fallback is disabled.');
      _SearchCache.set(cacheKey, const <PlaceResult>[]);
      return const <PlaceResult>[];
    }

    final results = await _fetchNearbyFromSupabase(
      lat: lat,
      lng: lng,
      keyword: keyword,
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      debugPrint('Supabase fallback timed out for "$keyword"');
      return const <PlaceResult>[];
    });
    _SearchCache.set(cacheKey, results);
    return results;
  }

  static Future<List<PlaceResult>> _fetchNearbyFromSupabase({
    required double lat,
    required double lng,
    required String keyword,
  }) async {
    try {
      final normalizedKeyword = keyword.toLowerCase();
      final mappedType = _normalizeKeywordToCategory(normalizedKeyword);

      final latDelta = _radiusMeters / 111000.0;
      final lngDelta = _radiusMeters /
          (111000.0 * math.max(0.1, math.cos(lat * math.pi / 180.0)));

      final response = mappedType == null
          ? await Supabase.instance.client
              .from('resources')
              .select(
                  'id,name,type,address,latitude,longitude,opening_hours,open_now,walk_in,appointment_required,id_required,cost,families_welcome,women_only,youth_friendly,phone,website,confidence_score')
              .gte('latitude', lat - latDelta)
              .lte('latitude', lat + latDelta)
              .gte('longitude', lng - lngDelta)
              .lte('longitude', lng + lngDelta)
              .order('confidence_score', ascending: false)
              .limit(100)
          : await Supabase.instance.client
              .from('resources')
              .select(
                  'id,name,type,address,latitude,longitude,opening_hours,open_now,walk_in,appointment_required,id_required,cost,families_welcome,women_only,youth_friendly,phone,website,confidence_score')
              .eq('type', mappedType)
              .gte('latitude', lat - latDelta)
              .lte('latitude', lat + latDelta)
              .gte('longitude', lng - lngDelta)
              .lte('longitude', lng + lngDelta)
              .order('confidence_score', ascending: false)
              .limit(100);

      final List<PlaceResult> results = [];
      for (final row in response) {
        final rowLat = (row['latitude'] as num?)?.toDouble();
        final rowLng = (row['longitude'] as num?)?.toDouble();
        if (rowLat == null || rowLng == null) continue;

        if (_haversineMeters(lat, lng, rowLat, rowLng) > _radiusMeters) {
          continue;
        }

        results.add(
          PlaceResult(
            placeId: (row['id'] ?? '').toString(),
            name: (row['name'] ?? 'Unknown').toString(),
            type: (row['type'] ?? mappedType ?? keyword).toString(),
            lat: rowLat,
            lng: rowLng,
            address: (row['address'] ?? '').toString(),
            openingHours: (row['opening_hours'] ?? '').toString(),
            openNow: row['open_now'] == true,
            walkIn: row['walk_in'] == true,
            appointmentRequired: row['appointment_required'] == true,
            idRequired: row['id_required'] == true,
            cost: (row['cost'] ?? 'unknown').toString(),
            familiesWelcome: row['families_welcome'] == true,
            womenOnly: row['women_only'] == true,
            youthFriendly: row['youth_friendly'] == true,
            phone: (row['phone'] ?? '').toString(),
            website: (row['website'] ?? '').toString(),
          ),
        );
      }

      results.sort((a, b) {
        final da = _haversineMeters(lat, lng, a.lat, a.lng);
        final db = _haversineMeters(lat, lng, b.lat, b.lng);
        return da.compareTo(db);
      });

      if (results.isNotEmpty) {
        debugPrint('Supabase nearby returned ${results.length} for "$keyword"');
      }
      return results;
    } catch (e) {
      debugPrint('Supabase nearby error for "$keyword": $e');
      return const <PlaceResult>[];
    }
  }

  static String? _normalizeKeywordToCategory(String keyword) {
    if (keyword.contains('shelter')) return 'shelter';
    if (keyword.contains('food')) return 'food';
    if (keyword.contains('mental')) return 'mental_health';
    if (keyword.contains('clinic') || keyword.contains('health')) {
      return 'clinic';
    }
    return null;
  }

  static double _haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * (math.pi / 180.0);

  // Actual API call (not cached)
  static Future<List<PlaceResult>> _fetchNearbyFromAPI({
    required double lat,
    required double lng,
    required String keyword,
  }) async {
    final normalizedKeyword = keyword.toLowerCase();
    final type = _googleTypeForKeyword(normalizedKeyword);
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
        final status = data['status']?.toString() ?? 'unknown';
        final errorMessage = data['error_message']?.toString();
        if (status == 'OVER_QUERY_LIMIT' || status == 'RESOURCE_EXHAUSTED') {
          debugPrint(
              'Places API quota exceeded: $status ${errorMessage ?? ''}');
        } else if (status == 'REQUEST_DENIED') {
          debugPrint(
              'Places API request denied: $status ${errorMessage ?? ''}');
        } else {
          debugPrint('Places API error: $status ${errorMessage ?? ''}');
        }
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
            address = p['formatted_address'].toString();
          } else if (p['vicinity'] != null &&
              p['vicinity'].toString().isNotEmpty) {
            address = p['vicinity'].toString();
          }
          final inferredType = _inferCategoryFromGooglePlace(p, keyword);
          final openingHoursObj = p['opening_hours'];
          final nearbyOpenNow = openingHoursObj is Map<String, dynamic>
              ? openingHoursObj['open_now'] == true
              : false;
          final place = PlaceResult(
            placeId: p['place_id'] as String? ?? '',
            name: p['name'] as String? ?? 'Unknown',
            lat: (loc['lat'] as num?)?.toDouble() ?? 0.0,
            lng: (loc['lng'] as num?)?.toDouble() ?? 0.0,
            type: inferredType,
            address: address,
            openNow: nearbyOpenNow,
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

  static String _inferCategoryFromGooglePlace(
    Map<String, dynamic> place,
    String keyword,
  ) {
    final types = (place['types'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        const <String>[];
    final name = (place['name'] as String? ?? '').toLowerCase();
    final context = name;

    if (types.contains('lodging') ||
        types.contains('homeless_shelter') ||
        context.contains('shelter') ||
        context.contains('homeless')) {
      return 'shelter';
    }
    if (types.contains('food') ||
        types.contains('meal_takeaway') ||
        types.contains('meal_delivery') ||
        types.contains('grocery_or_supermarket') ||
        context.contains('food bank') ||
        context.contains('soup kitchen')) {
      return 'food';
    }
    if (context.contains('mental') ||
        context.contains('counsel') ||
        context.contains('therapy') ||
        context.contains('psychiat') ||
        context.contains('psycholog')) {
      return 'other';
    }
    if (types.contains('hospital') ||
        types.contains('doctor') ||
        types.contains('health') ||
        context.contains('clinic')) {
      return 'clinic';
    }
    return 'other';
  }

  static String _googleTypeForKeyword(String keyword) {
    // Broad multi-service queries perform better without a hard type filter.
    if (keyword.contains('food bank') ||
        keyword.contains('soup kitchen') ||
        keyword.contains('mental health') ||
        keyword.contains('community health')) {
      return '';
    }
    if (keyword.contains('shelter')) return 'lodging';
    if (keyword.contains('food')) return 'food';
    if (keyword.contains('mental')) return 'health';
    if (keyword.contains('clinic') || keyword.contains('health')) {
      return 'doctor';
    }
    return typeMap[keyword] ?? '';
  }

  // Fetch details like phone, website (only call when user views resource)
  static Future<PlaceResult> fetchDetails(PlaceResult place) async {
    // Skip only if we already have all required details.
    if (place.phone.isNotEmpty &&
        place.website.isNotEmpty &&
        place.openingHours.isNotEmpty) {
      return place;
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      return place;
    }
    if (!_googleDetailsEnabled) {
      return place;
    }

    final detailsPlaceId = _isUuid(place.placeId)
        ? await _findGooglePlaceIdForResource(place)
        : place.placeId;
    if (detailsPlaceId == null || detailsPlaceId.isEmpty) {
      return place;
    }

    final url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$detailsPlaceId'
        '&fields=name,formatted_address,formatted_phone_number,website,opening_hours,current_opening_hours'
        '&key=$_apiKey';

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      final data = json.decode(res.body) as Map<String, dynamic>;

      if (res.statusCode != 200 || data['status'] != 'OK') {
        final status = data['status']?.toString() ?? 'unknown';
        final errorMessage = data['error_message']?.toString();
        if (status == 'OVER_QUERY_LIMIT' || status == 'RESOURCE_EXHAUSTED') {
          debugPrint(
            'Details API quota exceeded for ${place.name}: $status ${errorMessage ?? ''}',
          );
        } else if (status == 'REQUEST_DENIED') {
          debugPrint(
            'Details API request denied for ${place.name}: $status ${errorMessage ?? ''}',
          );
        } else {
          debugPrint(
            'Details API error for ${place.name}: $status ${errorMessage ?? ''}',
          );
        }
        return place;
      }

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return place;

      final hours = _extractOpeningHours(result);
      final openNow = _extractOpenNow(result) || _isAlwaysOpen(hours);
      final profile = await _inferEligibility(place: place, details: result);

      final enriched = place.copyWith(
        openingHours: hours,
        openNow: openNow,
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

      if (_isUuid(place.placeId)) {
        await _persistEnrichedResource(
            placeId: place.placeId, enriched: enriched);
      }

      return enriched;
    } catch (e) {
      debugPrint('Details error for ${place.name}: $e');
      return place;
    }
  }

  static bool _isUuid(String value) {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuid.hasMatch(value);
  }

  static Future<String?> _findGooglePlaceIdForResource(
      PlaceResult place) async {
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${place.lat},${place.lng}'
        '&radius=350'
        '&keyword=${Uri.encodeComponent(place.name)}'
        '&key=$_apiKey';

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200 || data['status'] != 'OK') return null;

      final results = data['results'];
      if (results is! List) return null;

      String? bestPlaceId;
      double bestScore = -1;

      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;
        final candidateId = item['place_id']?.toString();
        final candidateName = item['name']?.toString() ?? '';
        final loc = (item['geometry'] as Map<String, dynamic>?)?['location']
            as Map<String, dynamic>?;
        final cLat = (loc?['lat'] as num?)?.toDouble();
        final cLng = (loc?['lng'] as num?)?.toDouble();
        if (candidateId == null || cLat == null || cLng == null) continue;

        final distance = _haversineMeters(place.lat, place.lng, cLat, cLng);
        final nameScore = _nameSimilarity(place.name, candidateName);

        final score = nameScore - (distance / 1000.0);
        if (score > bestScore) {
          bestScore = score;
          bestPlaceId = candidateId;
        }
      }

      return bestPlaceId;
    } catch (_) {
      return null;
    }
  }

  static double _nameSimilarity(String a, String b) {
    final lhs = a.toLowerCase().trim();
    final rhs = b.toLowerCase().trim();
    if (lhs == rhs) return 2.0;
    if (lhs.contains(rhs) || rhs.contains(lhs)) return 1.5;

    final lhsWords =
        lhs.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final rhsWords =
        rhs.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    if (lhsWords.isEmpty || rhsWords.isEmpty) return 0.0;

    final overlap = lhsWords.intersection(rhsWords).length;
    return overlap / math.max(lhsWords.length, rhsWords.length);
  }

  static int _confidenceScore({
    required String phone,
    required String openingHours,
    required String website,
    required bool fromVerifiedDataset,
    required bool enrichedByGoogle,
  }) {
    var score = 0;
    if (phone.trim().isNotEmpty) score += 1;
    if (openingHours.trim().isNotEmpty) score += 1;
    if (website.trim().isNotEmpty) score += 1;
    if (fromVerifiedDataset) score += 2;
    if (enrichedByGoogle) score += 1;
    return score;
  }

  static Future<void> _persistEnrichedResource({
    required String placeId,
    required PlaceResult enriched,
  }) async {
    try {
      final row = await Supabase.instance.client
          .from('resources')
          .select('from_verified_dataset')
          .eq('id', placeId)
          .maybeSingle();

      final fromVerifiedDataset = row?['from_verified_dataset'] == true;
      final score = _confidenceScore(
        phone: enriched.phone,
        openingHours: enriched.openingHours,
        website: enriched.website,
        fromVerifiedDataset: fromVerifiedDataset,
        enrichedByGoogle: true,
      );

      await Supabase.instance.client.from('resources').update({
        'phone': enriched.phone,
        'website': enriched.website,
        'opening_hours': enriched.openingHours,
        'open_now': enriched.openNow,
        'walk_in': enriched.walkIn,
        'appointment_required': enriched.appointmentRequired,
        'id_required': enriched.idRequired,
        'cost': enriched.cost,
        'families_welcome': enriched.familiesWelcome,
        'women_only': enriched.womenOnly,
        'youth_friendly': enriched.youthFriendly,
        'address': enriched.address,
        'enriched_by_google': true,
        'confidence_score': score,
      }).eq('id', placeId);
    } catch (e) {
      debugPrint('Failed to persist enrichment for $placeId: $e');
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

  static bool _isAlwaysOpen(String openingHours) {
    final normalized = openingHours.toLowerCase();
    return normalized.contains('open 24 hours') ||
        normalized.contains('24 hours open') ||
        normalized.contains('open 24/7') ||
        normalized.contains('24/7');
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
    if (!_aiEnrichmentEnabled) return heuristic;
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
