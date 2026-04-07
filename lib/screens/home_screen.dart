import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../user_data.dart';
import '../models.dart';
import '../mock_resources.dart';
import 'chat_screen.dart';
import 'resource_detail_screen.dart';
import '../google_maps.dart';
import '../screens/places_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const String _resourceCacheKey = 'nearby_resources_cache_v1';
  static const String _lastKnownPositionCacheKey =
      'last_known_user_position_v1';
  static const LatLng _defaultFallbackPosition =
      LatLng(40.7128, -74.0060); // NYC fallback for emulator timeouts

  int _tab = 0;

  String userName = 'User';
  String userEmail = 'support@aidsense.app';

  final GlobalKey<_ProfileTabState> _profileKey = GlobalKey<_ProfileTabState>();

  // Shared resource state
  List<Resource> _resources = [];
  bool _loading = true;
  LatLng? _userPosition;
  bool _refreshingOnResume = false;
  DateTime? _lastResumeRefreshAt;

  bool _isPermissionGranted(PermissionStatus perm) {
    return perm == PermissionStatus.granted ||
        perm.toString().contains('grantedLimited');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _bootstrapResources();
    _refreshProfileFromSupabase();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNearbyOnResume();
    }
  }

  Future<void> _refreshNearbyOnResume() async {
    if (_refreshingOnResume) return;

    final now = DateTime.now();
    final last = _lastResumeRefreshAt;
    if (last != null && now.difference(last) < const Duration(seconds: 10)) {
      return;
    }

    _refreshingOnResume = true;
    _lastResumeRefreshAt = now;
    try {
      await _loadNearbyPlaces();
    } finally {
      _refreshingOnResume = false;
    }
  }

  Future<void> _bootstrapResources() async {
    await _loadCachedResources();
    await _loadNearbyPlaces();
  }

  Future<void> _refreshProfileFromSupabase() async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    await UserData.loadFromSupabase();
    FavoritesService().syncFromUserData();
    if (mounted) {
      setState(() {
        userName = UserData.fullName;
        userEmail = UserData.email;
      });
    }
  }

  void _loadUserData() {
    setState(() {
      userName = UserData.fullName;
      userEmail = UserData.email;
    });
  }

  Future<void> _loadCachedResources() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedResourcesRaw = prefs.getString(_resourceCacheKey);
    if (cachedResourcesRaw != null && cachedResourcesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedResourcesRaw) as List<dynamic>;
        final cachedResources = decoded
            .whereType<Map<String, dynamic>>()
            .map((entry) => Resource.fromMap(
                  (entry['id'] ?? '').toString(),
                  entry,
                ))
            .where((resource) => resource.id.isNotEmpty)
            .toList();

        if (cachedResources.isNotEmpty && mounted) {
          setState(() {
            _resources = cachedResources;
            _loading = false;
          });
        }
      } catch (_) {
        // Ignore cache parse issues and continue with a live fetch.
      }
    }

    final cachedPositionRaw = prefs.getString(_lastKnownPositionCacheKey);
    if (cachedPositionRaw != null && cachedPositionRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedPositionRaw) as Map<String, dynamic>;
        final latitude = (decoded['latitude'] as num?)?.toDouble();
        final longitude = (decoded['longitude'] as num?)?.toDouble();
        if (latitude != null && longitude != null && mounted) {
          setState(() {
            _userPosition = LatLng(latitude, longitude);
          });
        }
      } catch (_) {
        // Ignore cached position parse issues.
      }
    }
  }

  Future<void> _persistResourceCache(List<Resource> resources) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = resources
        .map(
          (resource) => {
            'id': resource.id,
            ...resource.toMap(),
          },
        )
        .toList();
    await prefs.setString(_resourceCacheKey, jsonEncode(payload));
  }

  Future<void> _persistLastKnownPosition(LatLng position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastKnownPositionCacheKey,
      jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }),
    );
  }

  Future<void> _loadNearbyPlaces() async {
    if (mounted) {
      setState(() => _loading = _resources.isEmpty);
    }
    try {
      final location = Location();
      LatLng pos = _userPosition ?? _defaultFallbackPosition;

      try {
        bool enabled =
            await location.serviceEnabled().timeout(const Duration(seconds: 5));
        if (!enabled) {
          enabled = await location
              .requestService()
              .timeout(const Duration(seconds: 8));
          if (!enabled) {
            debugPrint(
                'Location service unavailable, using fallback position.');
          }
        }

        PermissionStatus perm =
            await location.hasPermission().timeout(const Duration(seconds: 5));
        if (perm == PermissionStatus.denied) {
          perm = await location
              .requestPermission()
              .timeout(const Duration(seconds: 8));
        }

        if (_isPermissionGranted(perm) && enabled) {
          final loc = await location.getLocation().timeout(
                const Duration(seconds: 20),
              );
          if (loc.latitude != null && loc.longitude != null) {
            pos = LatLng(loc.latitude!, loc.longitude!);
          }
        }
      } on TimeoutException {
        debugPrint(
          'Location timed out, continuing with cached/default position.',
        );
      } catch (e) {
        debugPrint('Location fetch failed, continuing with fallback: $e');
      }

      final List<Resource> all = [];
      const categories = ['shelter', 'food', 'clinic', 'Mental Health'];
      final keywordMap = {
        'food': 'food bank soup kitchen',
        'shelter': 'homeless shelter',
        'clinic': 'free clinic community health',
        'Mental Health': 'mental health counseling therapy',
      };

      for (final c in categories) {
        try {
          final places = await PlacesService.fetchNearby(
            lat: pos.latitude,
            lng: pos.longitude,
            keyword: keywordMap[c]!,
          );
          final detailedPlaces = await Future.wait(
            places.take(10).map((p) => PlacesService.fetchDetails(p)),
          );
          all.addAll(
            detailedPlaces.map((p) {
              List<String> tags;
              switch (c) {
                case 'shelter':
                  tags = ['Housing', 'Assistance'];
                  break;
                case 'food':
                  tags = ['Groceries', 'Meals'];
                  break;
                case 'clinic':
                  tags = ['Medical', 'Care'];
                  break;
                case 'Mental Health':
                  tags = ['Counseling', 'Therapy', 'Support'];
                  break;
                default:
                  tags = [c];
              }
              return Resource(
                id: p.placeId,
                name: p.name,
                type: c,
                address: p.address,
                latitude: p.lat,
                longitude: p.lng,
                phone: p.phone,
                website: p.website,
                tags: tags,
              );
            }),
          );
        } catch (e) {
          debugPrint('Category load failed ($c): $e');
        }
      }

      // Keep favorites displayable across app restarts once resources are known.
      FavoritesService().registerResources(all);

      if (mounted) {
        setState(() {
          _userPosition = pos;
          _resources = all;
          _loading = false;
        });
      }
      await _persistLastKnownPosition(pos);
      await _persistResourceCache(all);

      if (all.isEmpty && mounted && _resources.isEmpty) {
        setState(() {
          _resources = mockResources;
        });
      }
    } catch (e) {
      debugPrint('Nearby load failed: $e');
      if (mounted && _resources.isEmpty) {
        setState(() {
          _resources = mockResources;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);

    return Scaffold(
      appBar: AppBar(
        leading: _tab == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _tab = 0),
              )
            : null,
        centerTitle: true,
        title: _tab == 1
            ? const Text('AI Assistant')
            : Text(_tab == 0 ? 'Resources' : 'Profile'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && mounted) {
                await Supabase.instance.client.auth.signOut();
                UserData.clearUser();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _MapAndListTab(
            resources: _resources,
            loading: _loading,
            userPosition: _userPosition,
          ),
          ChatScreen(resources: _resources),
          _ProfileTab(
              key: _profileKey,
              userName: userName,
              userEmail: userEmail,
              onProfileUpdated: () {
                setState(() {
                  userName = UserData.fullName;
                  userEmail = UserData.email;
                });
              }),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

/* ---------------- MAP + LIST TAB ---------------- */

class _MapAndListTab extends StatefulWidget {
  final List<Resource> resources;
  final bool loading;
  final LatLng? userPosition;
  const _MapAndListTab(
      {Key? key,
      required this.resources,
      required this.loading,
      required this.userPosition})
      : super(key: key);

  @override
  State<_MapAndListTab> createState() => _MapAndListTabState();
}

class _MapAndListTabState extends State<_MapAndListTab> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Resource> get _filteredPlaces {
    return widget.resources.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.tags.any(
              (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesFilter = _selectedFilter == 'All' ||
          _selectedFilter == 'all' ||
          r.type.toLowerCase() == _selectedFilter.toLowerCase();
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    final filters = ['All', 'Shelter', 'Food', 'Clinic', 'Mental Health'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search resources...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemBuilder: (c, i) {
              final f = filters[i];
              return FilterChip(
                selected: _selectedFilter == f,
                showCheckmark: false,
                label: Text(f),
                onSelected: (_) => setState(() => _selectedFilter = f),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: filters.length,
          ),
        ),
        Expanded(
          flex: 2,
          child: MapPage(
            resources: _filteredPlaces,
            searchQuery: _searchQuery,
            selectedFilter: _selectedFilter,
            initialPosition: widget.userPosition,
          ),
        ),
        Expanded(
          flex: 2,
          child: widget.loading && widget.resources.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _getLoadingMessage(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : _filteredPlaces.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                              'No resources found${_searchQuery.isNotEmpty ? ' for "$_searchQuery"' : ''}'),
                          if (_searchQuery.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Text('Clear search'),
                            ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredPlaces.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = _filteredPlaces[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primary.withOpacity(0.1),
                              child: Icon(_getResourceIcon(r.type),
                                  color: primary),
                            ),
                            title: Text(r.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (r.address.trim().isNotEmpty)
                                  Text(
                                    r.address,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (r.address.trim().isNotEmpty)
                                  const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  children: r.tags
                                      .map((tag) => Chip(
                                            label: Text(tag),
                                            backgroundColor: Colors.grey[200],
                                            labelStyle:
                                                const TextStyle(fontSize: 12),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.pushNamed(
                                context, '/resource',
                                arguments: r),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'shelter':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      case 'clinic':
        return Icons.local_hospital;
      case 'Mental Health':
        return Icons.psychology;
      default:
        return Icons.location_on;
    }
  }

  String _getLoadingMessage() {
    switch (_selectedFilter) {
      case 'Shelter':
        return 'Searching for shelters...';
      case 'Food':
        return 'Searching for food...';
      case 'Clinic':
        return 'Searching for clinics...';
      case 'Mental Health':
        return 'Searching for mental health services...';
      case 'All':
      default:
        return 'Searching for resources...';
    }
  }
}

/* ---------------- PROFILE TAB ---------------- */

class _ProfileTab extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onProfileUpdated;
  const _ProfileTab({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onProfileUpdated,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  String get userName => UserData.fullName;
  String get userEmail => UserData.email;
  String get userMobile => UserData.mobile;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    return Container(
      color: primary,
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Profile Picture Section
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB6C1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // User Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  userMobile.isNotEmpty ? userMobile : 'No phone number',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Profile Options
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildProfileOption(Icons.favorite_border, 'Favorites', () {
                    Navigator.pushNamed(context, '/favorites');
                  }),
                  _buildProfileOption(Icons.settings, 'Settings', () {
                    Navigator.pushNamed(context, '/settings');
                  }),
                  _buildProfileOption(Icons.help_outline, 'Help & Support', () {
                    Navigator.pushNamed(context, '/help');
                  }),
                  _buildProfileOption(
                      Icons.privacy_tip_outlined, 'Privacy Policy', () {
                    Navigator.pushNamed(context, '/privacy');
                  }),
                  _buildProfileOption(Icons.info_outline, 'About', () {
                    Navigator.pushNamed(context, '/about');
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFF48A8A)),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
