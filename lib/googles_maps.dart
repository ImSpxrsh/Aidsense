import 'package:aidsense_app/mock_resources.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final Location _locationController = Location();
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  static const LatLng _userPosition = LatLng(40.7178, -74.0431);
  static const LatLng jerseyCityShelter =
      LatLng(40.72038814879095, -74.03860961247194);
  LatLng? _currentP;

  final List<Marker> _markers = <Marker>[];

  final List<String> images = [
    'assets/images/person_marker.png',
    'assets/images/shelter_marker1.png',
    'assets/images/clinic_marker.png',
    'assets/images/food_bank_marker.png',
  ];

  @override
  void initState() {
    super.initState();
  }

  /// Load image from assets and convert to Uint8List
  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetHeight: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  /// Load user and resource markers
  Future<void> loadData() async {
    // User marker
    final Uint8List userIcon = await getImages(images[0], 50);
    _markers.add(
      Marker(
        markerId: const MarkerId("user"),
        icon: BitmapDescriptor.bytes(userIcon),
        position: _userPosition,
        infoWindow: const InfoWindow(title: "Your Position"),
        onTap: () => _centerMapOnMarker(_userPosition),
      ),
    );

    // Resource markers
    for (final resource in mockResources) {
      final String type = resource.type.toLowerCase();
      String imgPath;
      if (type.contains('shelter')) {
        imgPath = images[1];
      } else if (type.contains('clinic')) {
        imgPath = images[2];
      } else if (type.contains('food')) {
        imgPath = images[3];
      } else {
        imgPath = images[1]; // fallback
      }

      final Uint8List markIcon = await getImages(imgPath, 50);

      _markers.add(
        Marker(
          markerId: MarkerId(resource.id),
          icon: BitmapDescriptor.bytes(markIcon),
          position: LatLng(resource.latitude, resource.longitude),
          infoWindow: InfoWindow(title: resource.name),
          onTap: () => _centerMapOnMarker(
            LatLng(resource.latitude, resource.longitude),
          ),
        ),
      );
    }

    setState(() {}); // Refresh map with markers

    // Center map on user
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _centerMapOnMarker(_userPosition);
    });
  }

  Future<void> _centerMapOnMarker(LatLng target) async {
    if (_mapController == null) {
      _mapController = await _controllerCompleter.future;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLng(
          target), // marker is roughly centered in map widget
    );
  }

  @override
  Widget build(BuildContext context) {
    final allMarkers = Set<Marker>.of(_markers);

    return GoogleMap(
      initialCameraPosition:
          const CameraPosition(target: _userPosition, zoom: 14),
      markers: allMarkers,
      mapType: MapType.normal,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (!_controllerCompleter.isCompleted) {
          _controllerCompleter.complete(controller);
        }

        loadData(); // Ensure markers are loaded
      },
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      myLocationButtonEnabled: false,
      style: '''
      [
        {
          "featureType": "poi",
          "stylers": [{"visibility": "off"}]
        }
      ]
      ''',
    );
  }

  /// Granting permission to access user's real location
  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        _currentP =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_currentP!),
          );
        }
      }
    });
  }
}
