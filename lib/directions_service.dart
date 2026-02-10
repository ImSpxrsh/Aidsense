import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ORSService {
  final String apiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImU1ZmM5MWFkMDgwZTRjYTA4MjE0MzZhYzc1NGZkNjY1IiwiaCI6Im11cm11cjY0In0=';

  // Get walking route
  Future<List<LatLng>> getWalkingRoute(LatLng start, LatLng end) async {
    final url =
        'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final geometry = data['features'][0]['geometry']['coordinates'] as List;

    // Convert [lon, lat] pairs to LatLng
    return geometry
        .map((point) => LatLng(point[1] as double, point[0] as double))
        .toList();
  }

  // Get walking route with distance and duration
  Future<Map<String, dynamic>> getWalkingRouteWithInfo(
      LatLng start, LatLng end) async {
    final url =
        'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route: \\${response.statusCode}');
    }

    final data = json.decode(response.body);
    final geometry = data['features'][0]['geometry']['coordinates'] as List;
    final summary = data['features'][0]['properties']['summary'];
    final distance = summary['distance'] as num; // meters
    final duration = summary['duration'] as num; // seconds

    final points = geometry
        .map((point) => LatLng(point[1] as double, point[0] as double))
        .toList();

    return {
      'points': points,
      'distance': distance.toDouble(),
      'duration': duration.toDouble(),
    };
  }
}
