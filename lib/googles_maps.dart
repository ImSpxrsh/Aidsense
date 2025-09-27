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

  Location _locationController = new Location();

  static const LatLng _userPosition = LatLng(40.7178, -74.0431);
  static const LatLng jerseyCityShelter =
      LatLng(40.72038814879095, -74.03860961247194);
  LatLng? _currentP = null;

  Uint8List? aidImages;
  List<String> images = [
    'assets/images/person_marker.png',
    'assets/images/shelter_marker1.png',
    'assets/images/clinic_marker.png',
    'assets/images/food_bank_marker.png'
  ];

  final List<Marker> _markers = <Marker>[];

  // this the list of coordinates of the places
  final List<LatLng> _latLen = <LatLng>[
    _userPosition,
    LatLng(40.72038814879095, -74.03860961247194),
    LatLng(40.712378161806676, -74.07820608959999),
    LatLng(40.7144747152555, -74.07840710912085)
  ];

  List<String> names = [
    'Your Position',
    'Shelter',
    'Clinic',
    'Food Bank',
  ];

  // This is to get the Images
  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  @override
  void initState() {
    super.initState();
    loadData();
    _currentP = _userPosition;

    // Later we will use getLocationUpdates() to get real location
  }

  loadData() async {
    for (int i = 0; i < images.length; i++) {
      final Uint8List markIcons = await getImages(images[i], 50);
      _markers.add(Marker(
        markerId: MarkerId(i.toString()),
        icon: BitmapDescriptor.bytes(markIcons),
        position: _latLen[i],
        infoWindow: InfoWindow(title: names[i]),
      ));
    }
    setState(() {}); // refresh the map
  }

  @override
  Widget build(BuildContext context) {
    // If current position isn't ready, show loading
    if (_currentP == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allMarkers = Set<Marker>.of(_markers);
    return _currentP == null
        ? const Center(child: Text('Loading...'))
        : GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _userPosition, zoom: 14),
            markers: allMarkers,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            myLocationButtonEnabled: false,
            style: ('''
      [
        {
          "featureType": "poi",
          "stylers": [{"visibility": "off"}]
        }
      ]
    '''));
  }

  //Granting permission to access user's location
  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }
    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });

        // Move camera to current location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_currentP!),
          );
        }
      }
    });
  }
}
