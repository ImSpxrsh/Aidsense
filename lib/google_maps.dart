import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'dart:math';
import 'screens/places_service.dart';
import '../models.dart';

class MapPage extends StatefulWidget {
  final List<Resource> resources;
  final String searchQuery;
  final String selectedFilter;

  /// Position from parent (single location request). If set, map uses this instead of requesting location again.
  final LatLng? initialPosition;

  const MapPage({
    super.key,
    required this.resources,
    required this.searchQuery,
    required this.selectedFilter,
    this.initialPosition,
  });

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final Location _locationController = Location();
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  final Map<String, BitmapDescriptor> _resourceIcons = {};
  bool _iconsLoaded = false;

  BitmapDescriptor? _shelterIcon;
  BitmapDescriptor? _clinicIcon;
  BitmapDescriptor? _foodIcon;
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _mentalHealthIcon;

  LatLng? _userPosition;
  LatLng? _lastFetchedLocation;
  bool _isFirstLocation = true;

  final List<Marker> _markers = [];
  final Set<Polyline> _polylines = {}; // for directions

  final List<String> images = [
    'assets/images/person_marker.png',
    'assets/images/shelter_marker1.png',
    'assets/images/clinic_marker.png',
    'assets/images/food_bank_marker.png',
  ];

  final double _fetchThreshold = 0.2; // km

  List<String> getTagsForType(String type) {
    switch (type.toLowerCase()) {
      case 'shelter':
        return ['Beds', 'Warm meals'];
      case 'free clinic':
      case 'clinic':
        return ['Medical help', 'Checkups'];
      case 'food bank':
        return ['Groceries', 'Free meals'];
      default:
        return ['Community Support'];
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint("MapPage initState RUNNING");
    if (widget.initialPosition != null) {
      _userPosition = widget.initialPosition;
    }
    _loadResourceIcons();
    getLocationUpdates();
  }

  @override
  void didUpdateWidget(MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload markers if resources, searchQuery, or selectedFilter change
    if (widget.resources != oldWidget.resources ||
        widget.searchQuery != oldWidget.searchQuery ||
        widget.selectedFilter != oldWidget.selectedFilter) {
      loadData();
    }
    if (widget.initialPosition != null &&
        _userPosition != widget.initialPosition) {
      setState(() => _userPosition = widget.initialPosition);
      if (_iconsLoaded) loadData();
    }
  }

  Future<Uint8List> getImages(String path, int width) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetHeight: width,
    );
    final fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

//Load Icons
  Future<void> _loadResourceIcons() async {
    _userIcon = BitmapDescriptor.bytes(
      await getImages('assets/images/person_marker.png', 75),
    );
    _shelterIcon = BitmapDescriptor.bytes(
      await getImages('assets/images/shelter_marker1.png', 55),
    );
    _clinicIcon = BitmapDescriptor.bytes(
      await getImages('assets/images/clinic_marker.png', 55),
    );
    _foodIcon = BitmapDescriptor.bytes(
      await getImages('assets/images/food_bank_marker.png', 55),
    );
    _mentalHealthIcon = BitmapDescriptor.bytes(
      await getImages('assets/images/mental_health_marker.png', 85),
    );
    _resourceIcons['shelter'] = _shelterIcon!;
    _resourceIcons['clinic'] = _clinicIcon!;
    _resourceIcons['food'] = _foodIcon!;
    _resourceIcons['mental health'] = _mentalHealthIcon!;
    _resourceIcons['mental_health'] = _mentalHealthIcon!;
    _resourceIcons['other'] =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    _iconsLoaded = true;
    if (_userPosition != null) {
      loadData();
    }
  }

  Future<void> loadData() async {
    if (_userPosition == null || !_iconsLoaded) return;

    setState(() {
      _markers.clear();
    });

    // --- User Marker ---
    _markers.add(
      Marker(
        markerId: const MarkerId('user'),
        icon: _userIcon!,
        position: _userPosition!,
        infoWindow: const InfoWindow(title: 'You'),
      ),
    );

    // --- Show only resources passed from home_screen (already filtered) ---
    for (final r in widget.resources) {
      final d = distanceInKm(
        _userPosition!.latitude,
        _userPosition!.longitude,
        r.latitude,
        r.longitude,
      );
      String iconKey = _resourceIcons.keys.firstWhere(
        (k) => r.type.toLowerCase().contains(k),
        orElse: () => 'other',
      );
      final icon = _resourceIcons[iconKey]!;
      if (d <= 5.0) {
        _markers.add(
          Marker(
            markerId: MarkerId('resource_${r.id}'),
            position: LatLng(r.latitude, r.longitude),
            infoWindow: InfoWindow(
              title: r.name,
              snippet: [
                if (r.phone.isNotEmpty) 'Phone: ${r.phone}',
                if (r.website.isNotEmpty) 'Website: ${r.website}'
              ].join('\n'),
            ),
            icon: icon,
            onTap: () => _showResourceBottomSheet(r),
          ),
        );
      }
    }

    setState(() {});
  }

  Future<void> centerMapOnMarker(LatLng target) async {
    if (_mapController == null) {
      _mapController = await _controllerCompleter.future;
    }
    _mapController!.animateCamera(CameraUpdate.newLatLng(target));
  }

  @override
  Widget build(BuildContext context) {
    final allMarkers = Set<Marker>.of(_markers);
    if (_userPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: _userPosition!, zoom: 14),
          markers: allMarkers,
          polylines: _polylines,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            _mapController = controller;
            if (!_controllerCompleter.isCompleted)
              _controllerCompleter.complete(controller);
          },
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          myLocationButtonEnabled: false,
          // Hide POI labels
          style: '''
          [
            {
              "featureType": "poi",
              "stylers": [{"visibility": "off"}]
            }
          ]
          ''',
        ),
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'center_user',
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            onPressed: () {
              if (_userPosition != null) {
                centerMapOnMarker(_userPosition!);
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Future<void> getLocationUpdates() async {
    // Use position from parent only — single location request avoids timeout conflict
    if (widget.initialPosition != null) {
      if (mounted && _userPosition != widget.initialPosition) {
        setState(() => _userPosition = widget.initialPosition);
      }
      if (_iconsLoaded) loadData();
      _listenToLocationUpdates();
      return;
    }

    // No position from parent yet — show loading until parent gets real location
    _listenToLocationUpdates();
  }

  void _listenToLocationUpdates() {
    _locationController.onLocationChanged.listen((LocationData loc) {
      if (loc.latitude != null && loc.longitude != null && mounted) {
        final newPosition = LatLng(loc.latitude!, loc.longitude!);
        setState(() => _userPosition = newPosition);

        if (_lastFetchedLocation == null ||
            distanceInKm(
                  _userPosition!.latitude,
                  _userPosition!.longitude,
                  _lastFetchedLocation!.latitude,
                  _lastFetchedLocation!.longitude,
                ) >=
                _fetchThreshold) {
          loadData();
          _lastFetchedLocation = _userPosition;
        }
        if (_isFirstLocation) {
          centerMapOnMarker(_userPosition!);
          _isFirstLocation = false;
        }
      }
    });
  }

  double distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _showResourceBottomSheet(Resource resource) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resource.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(resource.address),
            if (resource.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Phone: ${resource.phone}'),
            ],
            if (resource.website.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Website: ${resource.website}'),
            ],
            const SizedBox(height: 4),
            Text('Tags: ${resource.tags.join(', ')}'),
          ],
        ),
      ),
    );
  }
}
