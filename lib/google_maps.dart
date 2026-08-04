import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'dart:math';

import '../models.dart';

class MapPage extends StatefulWidget {
  final List<Resource> resources;
  final String searchQuery;
  final String selectedFilter;
  final ValueChanged<LatLng>? onLocationResolved;

  /// Position from parent (single location request). If set, map uses this instead of requesting location again.
  final LatLng? initialPosition;

  const MapPage({
    super.key,
    required this.resources,
    required this.searchQuery,
    required this.selectedFilter,
    this.initialPosition,
    this.onLocationResolved,
  });

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  static const LatLng _fallbackPosition = LatLng(37.0902, -95.7129);

  GoogleMapController? _mapController;
  final Location _locationController = Location();
  StreamSubscription<LocationData>? _locationSubscription;
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
  bool _requestingLocation = false;
  bool _autoLocationAttempted = false;
  String? _locationIssue;

  final List<Marker> _markers = [];
  final Set<Polyline> _polylines = {};

  final double _fetchThreshold = 0.2;

  @override
  void initState() {
    super.initState();
    debugPrint('MapPage initState RUNNING');
    if (widget.initialPosition != null) {
      _userPosition = widget.initialPosition;
      // Ensure we attempt to center the map when an initial position is
      // provided (for example, after login). Wait for the map controller
      // to be ready and then animate the camera.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final controller = await _controllerCompleter.future;
          if (!mounted || _userPosition == null) return;
          controller.animateCamera(CameraUpdate.newLatLng(_userPosition!));
        } catch (_) {}
      });
    }
    _loadResourceIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        getLocationUpdates();
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resources != oldWidget.resources ||
        widget.searchQuery != oldWidget.searchQuery ||
        widget.selectedFilter != oldWidget.selectedFilter) {
      loadData();
    }
    if (widget.initialPosition != null &&
        _userPosition != widget.initialPosition) {
      setState(() {
        _userPosition = widget.initialPosition;
        _locationIssue = null;
      });
      // When parent provides a fresh position (e.g. after login), center map.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _userPosition == null) return;
        unawaited(centerMapOnMarker(_userPosition!));
      });
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
    if (!mounted) return;
    _iconsLoaded = true;
    if (_userPosition != null) {
      loadData();
    }
  }

  Future<void> loadData() async {
    if (!mounted || _userPosition == null || !_iconsLoaded) return;

    setState(() {
      _markers.clear();
    });

    _markers.add(
      Marker(
        markerId: const MarkerId('user'),
        icon: _userIcon!,
        position: _userPosition!,
        infoWindow: const InfoWindow(title: 'You'),
      ),
    );

    for (final r in widget.resources) {
      final d = distanceInKm(
        _userPosition!.latitude,
        _userPosition!.longitude,
        r.latitude,
        r.longitude,
      );
      final iconKey = _resourceIcons.keys.firstWhere(
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
              snippet: r.phone.trim().isNotEmpty
                  ? 'Phone: ${r.phone}'
                  : (r.website.isNotEmpty ? 'Website: ${r.website}' : ''),
            ),
            icon: icon,
            onTap: () => _showResourceBottomSheet(r),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> centerMapOnMarker(LatLng target) async {
    if (_mapController == null) {
      _mapController = await _controllerCompleter.future;
    }
    _mapController!.animateCamera(CameraUpdate.newLatLng(target));
  }

  LatLng get _mapCenter =>
      _userPosition ?? widget.initialPosition ?? _fallbackPosition;

  @override
  Widget build(BuildContext context) {
    final allMarkers = Set<Marker>.of(_markers);
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 14),
          markers: allMarkers,
          polylines: _polylines,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            _mapController = controller;
            if (!_controllerCompleter.isCompleted) {
              _controllerCompleter.complete(controller);
            }
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
        ),
        if (_userPosition == null)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withOpacity(0.05),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          minHeight: 4,
                          color: const Color(0xFFF48A8A),
                          backgroundColor: const Color(0xFFF1D6D6),
                          value: _requestingLocation ? null : 1,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _requestingLocation
                              ? 'Checking your location...'
                              : (_locationIssue ??
                                  'Showing a fallback map while location loads.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          // account for system bottom inset (navigation bar) so the FAB
          // doesn't overflow on devices with gesture/navigation bars
          bottom: 24 + MediaQuery.of(context).padding.bottom,
          right: 16,
          child: SafeArea(
            bottom: false,
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
        ),
      ],
    );
  }

  Future<void> getLocationUpdates() async {
    if (widget.initialPosition != null) {
      if (mounted && _userPosition != widget.initialPosition) {
        setState(() => _userPosition = widget.initialPosition);
      }
      if (mounted) {
        setState(() {
          _locationIssue = null;
        });
      }
      if (_iconsLoaded) loadData();
      _listenToLocationUpdates();
      return;
    }

    if (!_autoLocationAttempted) {
      _autoLocationAttempted = true;
      await _ensureLocationAndFetch(requestIfNeeded: true);
      return;
    }

    if (!mounted) return;
    setState(() {
      _locationIssue =
          'Location is not available right now. Tap "Use My Location" to try again.';
    });
  }

  bool _isPermissionGranted(PermissionStatus perm) {
    return perm == PermissionStatus.granted ||
        perm.toString().contains('grantedLimited');
  }

  Future<void> _ensureLocationAndFetch({required bool requestIfNeeded}) async {
    if (!mounted || _requestingLocation) return;
    setState(() {
      _requestingLocation = true;
      _locationIssue = null;
    });
    try {
      PermissionStatus perm = await _locationController.hasPermission();
      if (!_isPermissionGranted(perm) && requestIfNeeded) {
        perm = await _locationController.requestPermission();
      }
      if (!_isPermissionGranted(perm)) {
        if (!mounted) return;
        setState(() {
          _locationIssue = perm == PermissionStatus.deniedForever
              ? 'Location permission is blocked by iOS/Android settings. Enable it in system settings and try again.'
              : 'Location permission is required. Please allow access and try again.';
        });
        return;
      }

      bool enabled = await _locationController.serviceEnabled();
      if (!enabled && requestIfNeeded) {
        enabled = await _locationController.requestService();
      }
      if (!enabled) {
        if (!mounted) return;
        setState(() {
          _locationIssue =
              'Location services are off. Enable location in system settings and try again.';
        });
        return;
      }

      final loc = await _locationController.getLocation();
      if (loc.latitude == null || loc.longitude == null) {
        if (!mounted) return;
        setState(() {
          _locationIssue = 'Could not read your location yet. Try again.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _userPosition = LatLng(loc.latitude!, loc.longitude!);
        _locationIssue = null;
      });
      // Center immediately after obtaining the first reliable location.
      await centerMapOnMarker(_userPosition!);
      _isFirstLocation = false;
      widget.onLocationResolved?.call(_userPosition!);
      if (_iconsLoaded) loadData();
      _listenToLocationUpdates();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationIssue = 'Unable to fetch location right now.';
      });
    } finally {
      if (mounted) setState(() => _requestingLocation = false);
    }
  }

  void _listenToLocationUpdates() {
    if (_locationSubscription != null) return;
    _locationSubscription =
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
