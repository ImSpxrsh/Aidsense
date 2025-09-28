import 'package:flutter/material.dart';
import '../models.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'polyline_service.dart';

class ResourceDetailScreen extends StatelessWidget {
  const ResourceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Resource r = ModalRoute.of(context)!.settings.arguments as Resource;
    const primary = Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(title: Text(r.name), backgroundColor: primary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                      r.latitude, r.longitude), // use your resource's lat/lng
                  zoom: 15,
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
              children: r.tags.map((t) => Chip(label: Text(t))).toList()),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final polylineService = PolylineService();
                  final markers = await polylineService.createMarkers(
                    r
                  );
                  final polylines = await polylineService
                      .getPolyline(r);
 
                  // Navigate to a new map screen with polyline
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DirectionsMapScreen(
                        markers: markers,
                        polylines: polylines,
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
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening phone app...')),
                  );
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening website...')),
                  );
                },
                icon: const Icon(Icons.language),
                label: const Text('Website'),
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
                      FavoritesService().toggleFavorite(r);
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
          ]),
        ],
      ),
    );
  }
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
