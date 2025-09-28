import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  final String apiKey = 'AIzaSyCoteWOWkYDr7Keu4hWFZe6kI-hrp_A7ok';

  Future<List<LatLng>> getWalkingRoute(LatLng origin, LatLng destination) async {
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'walking',
        'key': apiKey,
      },
    );

    final response = await http.get(url);

    print('Request URL: $url'); // Debug: see the exact request
    print('Response code: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch directions. Status code: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    print('API Response: $data'); // Debug: see the full API response

    if (data['status'] != 'OK') {
      throw Exception('Directions API returned status: ${data['status']}');
    }

    if (data['routes'].isEmpty) {
      print('No routes found');
      return [];
    }

    final points = data['routes'][0]['overview_polyline']['points'];
    return _decodePolyline(points);
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return polyline;
  }
}
