import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../user_data.dart';
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
                      if (!context.mounted) return;
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
                child: OutlinedButton.icon(
                  onPressed: r.phone.trim().isEmpty
                      ? null
                      : () async {
                          final ok = await _callResourcePhone(r.phone);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open phone app'),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.phone),
                  label: Text(
                    r.phone.trim().isEmpty ? 'No Phone' : 'Call',
                    style: const TextStyle(
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
                    if (!context.mounted) return;

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

Future<bool> _callResourcePhone(String phone) async {
  final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalized.isEmpty) return false;

  final uri = Uri(scheme: 'tel', path: normalized);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

// To add favorites
class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal() {
    _hydrate();
  }

  final List<Resource> _favorites = [];
  final Map<String, Resource> _resourceRegistry = {};
  final Set<String> _favoriteIds = {};

  static const _favoritesCacheKey = 'favorites_resource_cache_v1';

  Future<void> _hydrate() async {
    // Start from Supabase-backed ids loaded into UserData.
    _favoriteIds
      ..clear()
      ..addAll(UserData.favorites);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesCacheKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final entry in decoded) {
          if (entry is! Map<String, dynamic>) continue;
          final id = (entry['id'] ?? '').toString();
          if (id.isEmpty) continue;
          final resource = Resource.fromMap(id, entry);
          _resourceRegistry[id] = resource;
        }
      } catch (_) {
        // Ignore cache parsing issues and continue with empty cache.
      }
    }
    _refreshFavoritesList();
    notifyListeners();
  }

  Future<void> _persistCache() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _resourceRegistry.values
        .map((r) => {
              'id': r.id,
              ...r.toMap(),
            })
        .toList();
    await prefs.setString(_favoritesCacheKey, jsonEncode(payload));
  }

  Future<void> _persistFavoritesToUser() async {
    UserData.setFavorites(_favoriteIds.toList());
    try {
      await UserData.saveToSupabase();
    } catch (_) {
      // Keep local state when network/RLS fails; sync can retry later.
    }
  }

  void _refreshFavoritesList() {
    _favorites
      ..clear()
      ..addAll(
        _favoriteIds
            .map((id) => _resourceRegistry[id])
            .whereType<Resource>()
            .toList(),
      );
  }

  void syncFromUserData() {
    _favoriteIds
      ..clear()
      ..addAll(UserData.favorites);
    _refreshFavoritesList();
    notifyListeners();
  }

  void registerResources(Iterable<Resource> resources) {
    var changed = false;
    for (final r in resources) {
      final existing = _resourceRegistry[r.id];
      if (existing == null || existing.name != r.name) {
        _resourceRegistry[r.id] = r;
        changed = true;
      }
    }
    if (changed) {
      _refreshFavoritesList();
      notifyListeners();
      _persistCache();
    }
  }

  List<Resource> get favorites => _favorites;

  bool isFavorite(Resource r) => _favoriteIds.contains(r.id);

  void toggleFavorite(Resource r) {
    _resourceRegistry[r.id] = r;
    if (_favoriteIds.contains(r.id)) {
      _favoriteIds.remove(r.id);
    } else {
      _favoriteIds.add(r.id);
    }
    _refreshFavoritesList();
    notifyListeners();
    _persistFavoritesToUser();
    _persistCache();
  }
}
