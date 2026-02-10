import 'package:aidsense_app/directions_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../models.dart';
import 'dart:async';

class PolylineService {
  final ORSService orsService = ORSService();

  /// Load a marker image from assets and resize
  Future<BitmapDescriptor> _getMarkerIcon(String path, int size) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetHeight: size,
      targetWidth: size,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final Uint8List bytes =
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
    return BitmapDescriptor.bytes(bytes);
  }

  /// Create custom markers for user and resource
  Future<Set<Marker>> createMarkers(
      Resource resource, LatLng userPosition) async {
    final userIcon =
        await _getMarkerIcon('assets/images/person_marker.png', 36);

    final type = resource.type.toLowerCase().trim();

    String iconPath;
    switch (type) {
      case 'shelter':
        iconPath = 'assets/images/shelter_marker1.png';
        break;
      case 'clinic':
        iconPath = 'assets/images/clinic_marker.png';
        break;
      case 'food':
      case 'food_bank':
        iconPath = 'assets/images/food_bank_marker.png';
        break;
      case 'mental health':
      case 'mental_health':
        iconPath = 'assets/images/mental_health_marker.png';
        break;
      default:
        iconPath = 'assets/images/shelter_marker1.png';
    }

    final destIcon = await _getMarkerIcon(iconPath, 50);

    return {
      Marker(
        markerId: const MarkerId('user'),
        position: userPosition,
        icon: userIcon,
        infoWindow: const InfoWindow(title: 'Your Position'),
      ),
      Marker(
        markerId: MarkerId(resource.id),
        position: LatLng(resource.latitude, resource.longitude),
        icon: destIcon,
        infoWindow: InfoWindow(
          title: resource.name,
          snippet: [
            if (resource.phone.isNotEmpty) 'Phone: ${resource.phone}',
            if (resource.website.isNotEmpty) 'Website: ${resource.website}'
          ].join('\n'),
        ),
      ),
    };
  }

  /// Get walking route polyline from ORS
  Future<Set<Polyline>> getPolyline(
      Resource resource, LatLng userPosition) async {
    final points = await orsService.getWalkingRoute(
        userPosition, LatLng(resource.latitude, resource.longitude));
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: const Color(0xFFF48A8A),
        width: 5,
      ),
    };
  }

  /// Get walking route polyline from ORS and return polyline, distance (meters), and duration (seconds)
  Future<Map<String, dynamic>> getPolylineWithInfo(
      Resource resource, LatLng userPosition) async {
    final routeInfo = await orsService.getWalkingRouteWithInfo(
        userPosition, LatLng(resource.latitude, resource.longitude));
    // routeInfo: { 'points': List<LatLng>, 'distance': double (meters), 'duration': double (seconds) }
    final points = routeInfo['points'] as List<LatLng>;
    final distance = routeInfo['distance'] as double;
    final duration = routeInfo['duration'] as double;
    return {
      'polyline': {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: const Color(0xFFF48A8A),
          width: 7,
        ),
      },
      'distance': distance,
      'duration': duration,
    };
  }
}

/// Directions Map Screen
class DirectionsMapScreen extends StatefulWidget {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final LatLng userPosition;
  final double? distance;
  final double? duration;

  const DirectionsMapScreen({
    super.key,
    required this.markers,
    required this.polylines,
    required this.userPosition,
    this.distance,
    this.duration,
  });

  @override
  State<DirectionsMapScreen> createState() => _DirectionsMapScreenState();
}

class _DirectionsMapScreenState extends State<DirectionsMapScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  Set<Marker> _displayMarkers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF48A8A),
        iconTheme:
            const IconThemeData(color: Colors.white), // makes back button white
        title: const Text(
          'Directions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          if (widget.distance != null && widget.duration != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Distance: ${(widget.distance! / 1000).toStringAsFixed(2)} km',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'Time: ${(widget.duration! / 60).toStringAsFixed(0)} min',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.userPosition,
                zoom: 15, // Slightly more zoomed in
              ),
              polylines: widget.polylines,
              markers: _displayMarkers,
              onMapCreated: (controller) async {
                if (!_controllerCompleter.isCompleted) {
                  _controllerCompleter.complete(controller);
                }
                await Future.delayed(const Duration(milliseconds: 300));
                setState(() {
                  _displayMarkers = widget.markers;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
