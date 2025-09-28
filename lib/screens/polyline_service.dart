import 'package:aidsense_app/directions_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../models.dart';

class PolylineService {
  static const LatLng _userPosition = LatLng(40.7178, -74.0431);
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
    return BitmapDescriptor.fromBytes(bytes);
  }

  /// Create custom markers for user and resource
  Future<Set<Marker>> createMarkers(Resource resource) async {
    final userIcon =
        await _getMarkerIcon('assets/images/person_marker.png', 150);

    String iconPath;
    switch (resource.type) {
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
      default:
        iconPath = 'assets/images/shelter_marker1.png';
    }

    final destIcon = await _getMarkerIcon(iconPath, 150);

    return {
      Marker(
        markerId: const MarkerId('user'),
        position: _userPosition,
        icon: userIcon,
        infoWindow: const InfoWindow(title: 'Your Position'),
      ),
      Marker(
        markerId: MarkerId(resource.id),
        position: LatLng(resource.latitude, resource.longitude),
        icon: destIcon,
        infoWindow: InfoWindow(title: resource.name),
      ),
    };
  }

  /// Get walking route polyline from ORS
  Future<Set<Polyline>> getPolyline(Resource resource) async {
    final points = await orsService.getWalkingRoute(
        _userPosition, LatLng(resource.latitude, resource.longitude));
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: const Color(0xFFF48A8A),
        width: 5,
      ),
    };
  }
}

/// Directions Map Screen
class DirectionsMapScreen extends StatefulWidget {
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const DirectionsMapScreen({
    super.key,
    required this.markers,
    required this.polylines,
  });

  @override
  State<DirectionsMapScreen> createState() => _DirectionsMapScreenState();
}

class _DirectionsMapScreenState extends State<DirectionsMapScreen> {
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  void _fitBounds() {
    if (_controller == null || widget.markers.isEmpty) return;

    final lats = widget.markers.map((m) => m.position.latitude).toList();
    final lngs = widget.markers.map((m) => m.position.longitude).toList();

    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce((a, b) => a < b ? a : b),
          lngs.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(lats.reduce((a, b) => a > b ? a : b),
          lngs.reduce((a, b) => a > b ? a : b)),
    );

    _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Directions')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
            target: widget.markers.first.position, zoom: 14),
        markers: widget.markers,
        polylines: widget.polylines,
        onMapCreated: (controller) => _controller = controller,
      ),
    );
  }
}
