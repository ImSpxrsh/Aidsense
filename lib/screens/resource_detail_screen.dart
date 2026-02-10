import 'package:flutter/material.dart';
import '../models.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'polyline_service.dart';
import 'chat_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceDetailScreen extends StatelessWidget {
  const ResourceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Resource r = ModalRoute.of(context)!.settings.arguments as Resource;
    const primary = Color(0xFFF48A8A);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(r.name),
        backgroundColor: primary,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 220, // Less zoomed in
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(r.latitude, r.longitude),
                  zoom: 13, // Less zoom for wider view
                ),
                markers: {
                  Marker(
                    markerId: MarkerId(r.name),
                    position: LatLng(r.latitude, r.longitude),
                    infoWindow: InfoWindow(title: r.name),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(r.address, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: r.tags.map((t) => Chip(label: Text(t))).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final url = r.website.startsWith('http')
                        ? r.website
                        : 'https://${r.website}';
                    try {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not launch website')),
                      );
                    }
                  },
                  icon: const Icon(Icons.language),
                  label: const Text(
                    'Website',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF48A8A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final phoneUri = Uri(scheme: 'tel', path: r.phone);
                    try {
                      await launchUrl(phoneUri);
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not launch phone app')),
                      );
                    }
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text(
                    'Call',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF48A8A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final userLatLng = await _getUserLatLng();
                    final polylineService = PolylineService();
                    final routeInfo = await polylineService.getPolylineWithInfo(
                        r, userLatLng);
                    final markers =
                        await polylineService.createMarkers(r, userLatLng);
                    final polylines = routeInfo['polyline'] as Set<Polyline>;
                    final distance = routeInfo['distance'] as double;
                    final duration = routeInfo['duration'] as double;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectionsMapScreen(
                          userPosition: userLatLng,
                          markers: markers,
                          polylines: polylines,
                          distance: distance,
                          duration: duration,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedBuilder(
                  animation: FavoritesService(),
                  builder: (context, _) {
                    final added = FavoritesService().isFavorite(r);
                    return ElevatedButton.icon(
                      onPressed: () {
                        final favoritesService = FavoritesService();
                        favoritesService.toggleFavorite(r);
                        final nowAdded = favoritesService.isFavorite(r);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(nowAdded
                                ? 'Added to favorites!'
                                : 'Removed from favorites!'),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.favorite,
                        color: added ? Colors.red : Colors.white,
                      ),
                      label: const Text('Favorite'),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          initialResource: r,
                          showAppBar: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white),
                  label: const Text(
                    'Ask AI',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<LatLng> _getUserLatLng() async {
  Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  return LatLng(pos.latitude, pos.longitude);
}

// To add favorites
class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final List<Resource> _favorites = [];

  List<Resource> get favorites => _favorites;

  bool isFavorite(Resource r) => _favorites.contains(r);

  void toggleFavorite(Resource r) {
    if (_favorites.contains(r)) {
      _favorites.remove(r);
    } else {
      _favorites.add(r);
    }
    notifyListeners();
  }
}
