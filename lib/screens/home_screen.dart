import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../user_data.dart';
import '../models.dart';
import '../providers.dart';
import '../google_auth.dart';
import 'chat_screen.dart';
import 'resource_detail_screen.dart';
import '../google_maps.dart';
import '../screens/places_service.dart';
import '../app_events.dart';
import '../nearby_refresh_logic.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const String _resourceCacheKey = 'nearby_resources_cache_v2';
  static const String _lastKnownPositionCacheKey =
      'last_known_user_position_v1';
  static const Duration _resumeRefreshMinGap = Duration(minutes: 2);
  static const Duration _backgroundRefreshThreshold = Duration(seconds: 25);

  int _tab = 0;

  String userName = 'User';
  String userEmail = '';

  final GlobalKey<_ProfileTabState> _profileKey = GlobalKey<_ProfileTabState>();

  // Shared resource state
  List<Resource> _resources = [];
  bool _loading = true;
  String? _loadingStageLabel;
  LatLng? _userPosition;
  bool _refreshingOnResume = false;
  DateTime? _lastResumeRefreshAt;
  DateTime? _lastBackgroundAt;
  bool _loadingNearby = false;
  String? _lastNearbyFetchSignature;
  StreamSubscription<void>? _appEventsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(requireFreshLocationOnLaunchProvider.notifier).state = true;
    });
    // Listen for global refresh signals (e.g. after auth sign-in)
    _appEventsSub = AppEvents.onRefreshResources.listen((_) async {
      if (!mounted) return;
      // Force a fresh location and resource load
      ref.read(requireFreshLocationOnLaunchProvider.notifier).state = true;
      await _loadNearbyPlaces();
    });
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _bootstrapResources();
    _refreshProfileFromSupabase();
  }

  @override
  void dispose() {
    _appEventsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lastBackgroundAt = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      _refreshNearbyOnResume();
    }
  }

  Future<void> _refreshNearbyOnResume() async {
    if (_refreshingOnResume) return;

    final backgroundAt = _lastBackgroundAt;
    if (backgroundAt != null &&
        DateTime.now().difference(backgroundAt) < _backgroundRefreshThreshold) {
      return;
    }

    final now = DateTime.now();
    final last = _lastResumeRefreshAt;
    if (last != null && now.difference(last) < _resumeRefreshMinGap) {
      return;
    }

    _refreshingOnResume = true;
    _lastResumeRefreshAt = now;
    try {
      await _loadNearbyPlaces(forcedPosition: _userPosition);
    } finally {
      _refreshingOnResume = false;
    }
  }

  Future<void> _bootstrapResources() async {
    await _loadCachedResources();

    unawaited(_loadNearbyPlaces());
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

  Future<void> _loadNearbyPlaces({LatLng? forcedPosition}) async {
    if (_loadingNearby) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingStageLabel = null;
        });
      }
      return;
    }
    final mustCheckFresh = ref.read(requireFreshLocationOnLaunchProvider) &&
        forcedPosition == null;

    final effectivePosition = forcedPosition ?? _userPosition;
    final fetchSignature = effectivePosition == null
        ? null
        : '${effectivePosition.latitude.toStringAsFixed(4)},${effectivePosition.longitude.toStringAsFixed(4)}';

    final shouldRefresh = NearbyRefreshLogic.shouldFetch(
      hasExistingResources: _resources.isNotEmpty,
      forceRefresh: forcedPosition != null || mustCheckFresh,
      requireFreshLocation: mustCheckFresh,
      currentSignature: fetchSignature,
      lastSignature: _lastNearbyFetchSignature,
    );

    if (!shouldRefresh) {
      return;
    }

    _loadingNearby = true;
    _lastNearbyFetchSignature = fetchSignature;

    if (mounted) {
      setState(() {
        _loading = _resources.isEmpty;
        if (_loading) {
          _loadingStageLabel = 'Searching for resources...';
        }
      });
    }
    try {
      final queryPosition = forcedPosition ?? _userPosition;
      if (queryPosition == null) {
        // Wait for a real location instead of querying a fixed fallback city.
        return;
      }

      final List<Resource> all = [];
      const broadQueries = [
        'homeless shelter food bank soup kitchen',
        'free clinic community health',
      ];

      final fetched = await Future.wait(
        broadQueries.map((query) async {
          if (mounted && _loading) {
            setState(() => _loadingStageLabel = 'Searching for resources...');
          }
          try {
            final places = await PlacesService.fetchNearby(
              lat: queryPosition.latitude,
              lng: queryPosition.longitude,
              keyword: query,
            ).timeout(const Duration(seconds: 20));
            return places.map((p) {
              final category = _deriveResourceCategory(
                place: p,
                sourceQuery: query,
              );
              List<String> tags;
              switch (category) {
                case 'shelter':
                  tags = ['Housing', 'Assistance'];
                  break;
                case 'food':
                  tags = ['Groceries', 'Meals'];
                  break;
                case 'clinic':
                  tags = ['Medical', 'Care'];
                  break;
                default:
                  tags = ['Resource'];
              }

              return Resource(
                id: p.placeId,
                name: p.name,
                type: category,
                address: p.address,
                openingHours: p.openingHours,
                openNow: p.openNow,
                walkIn: p.walkIn,
                appointmentRequired: p.appointmentRequired,
                idRequired: p.idRequired,
                cost: p.cost,
                familiesWelcome: p.familiesWelcome,
                womenOnly: p.womenOnly,
                youthFriendly: p.youthFriendly,
                latitude: p.lat,
                longitude: p.lng,
                tags: tags,
                phone: p.phone,
                website: p.website,
              );
            }).toList();
          } catch (e) {
            debugPrint('Nearby query load failed ($query): $e');
            return <Resource>[];
          }
        }),
      );

      for (final resources in fetched) {
        all.addAll(resources);
      }

      // Deduplicate by place id, then keep strongest per category.
      final byId = <String, Resource>{};
      for (final resource in all) {
        final existing = byId[resource.id];
        if (existing == null) {
          byId[resource.id] = resource;
          continue;
        }

        // Prefer meaningful aid categories over generic/other on duplicate ids.
        final existingScore = _categoryPriority(existing.type);
        final incomingScore = _categoryPriority(resource.type);
        if (incomingScore > existingScore) {
          byId[resource.id] = resource;
        }
      }

      final shelters = byId.values.where((r) => r.type == 'shelter').take(3);
      final food = byId.values.where((r) => r.type == 'food').take(3);
      final clinics = byId.values.where((r) => r.type == 'clinic').take(3);
      final finalResources = [
        ...shelters,
        ...food,
        ...clinics,
      ];

      // Keep favorites displayable across app restarts once resources are known.
      FavoritesService().registerResources(finalResources);

      if (mounted) {
        setState(() {
          _userPosition = queryPosition;
          _resources = finalResources;
          _loading = false;
        });
      }
      if (forcedPosition != null) {
        ref.read(requireFreshLocationOnLaunchProvider.notifier).state = false;
        await _persistLastKnownPosition(forcedPosition);
      } else if (_userPosition != null) {
        ref.read(requireFreshLocationOnLaunchProvider.notifier).state = false;
        await _persistLastKnownPosition(_userPosition!);
      }
      await _persistResourceCache(finalResources);

      if (finalResources.isEmpty && mounted && _resources.isEmpty) {
        setState(() {
          _loadingStageLabel = null;
        });
      }
    } catch (e) {
      debugPrint('Nearby load failed: $e');
      if (mounted) {
        setState(() {
          _loadingStageLabel = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingStageLabel = null;
        });
      }
      _loadingNearby = false;
    }
  }

  int _categoryPriority(String type) {
    switch (type.toLowerCase()) {
      case 'shelter':
        return 4;
      case 'clinic':
        return 3;
      case 'food':
        return 2;
      case 'other':
      default:
        return 1;
    }
  }

  String _displayTypeFromCategory(String rawType) {
    final t = rawType.toLowerCase();
    if (t.contains('shelter')) return 'shelter';
    if (t.contains('food')) return 'food';
    if (t.contains('clinic') || t.contains('health') || t.contains('doctor')) {
      return 'clinic';
    }
    return 'other';
  }

  String _deriveResourceCategory({
    required PlaceResult place,
    required String sourceQuery,
  }) {
    final fromType = _displayTypeFromCategory(place.type);
    if (fromType != 'other') return fromType;

    final q = sourceQuery.toLowerCase();
    final name = place.name.toLowerCase();

    if (q.contains('homeless shelter')) {
      // The shelter query intentionally mixes shelter + food terms.
      // Default to shelter unless the place name clearly indicates food-only service.
      final looksFoodOnly = name.contains('food bank') ||
          name.contains('soup kitchen') ||
          name.contains('pantry') ||
          name.contains('meal');
      return looksFoodOnly ? 'food' : 'shelter';
    }

    if (q.contains('free clinic') || q.contains('community health')) {
      return 'clinic';
    }

    return 'other';
  }

  Future<void> _onMapLocationResolved(LatLng position) async {
    if (!mounted) return;
    ref.read(requireFreshLocationOnLaunchProvider.notifier).state = false;
    setState(() {
      _userPosition = position;
      _loading = true;
      _loadingStageLabel = 'Searching for resources...';
    });
    await _loadNearbyPlaces(forcedPosition: position);
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
                // Use centralized sign-out to clear native SDK sessions
                // and cached app state that can cause stale account behavior.
                await signOutAll();
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
            loadingStageLabel: _loadingStageLabel,
            userPosition: ref.watch(requireFreshLocationOnLaunchProvider)
                ? null
                : _userPosition,
            onLocationResolved: _onMapLocationResolved,
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
  final String? loadingStageLabel;
  final LatLng? userPosition;
  final ValueChanged<LatLng> onLocationResolved;
  const _MapAndListTab(
      {Key? key,
      required this.resources,
      required this.loading,
      this.loadingStageLabel,
      required this.userPosition,
      required this.onLocationResolved})
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
    final filters = ['All', 'Shelter', 'Food', 'Clinic'];
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (var i = 0; i < filters.length; i++) ...[
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilterChip(
                      selected: _selectedFilter == filters[i],
                      showCheckmark: false,
                      label: Text(
                        filters[i],
                        textAlign: TextAlign.center,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedFilter = filters[i]),
                    ),
                  ),
                ),
                if (i != filters.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: MapPage(
            resources: _filteredPlaces,
            searchQuery: _searchQuery,
            selectedFilter: _selectedFilter,
            initialPosition: widget.userPosition,
            onLocationResolved: widget.onLocationResolved,
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
                        _getLoadingMessage(widget.loadingStageLabel),
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
                        final isOpenNow = _isOpenNow(r);
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
                                Text(
                                  r.address.trim().isNotEmpty
                                      ? r.address
                                      : 'Address unavailable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: r.address.trim().isNotEmpty
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isOpenNow
                                        ? Colors.green.withOpacity(0.12)
                                        : Colors.red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isOpenNow ? 'Open now' : 'Closed now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isOpenNow
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Schedule navigation after frame to avoid
                              // Navigator being locked during list builds/transitions.
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                Navigator.pushNamed(context, '/resource',
                                    arguments: r);
                              });
                            },
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
      default:
        return Icons.location_on;
    }
  }

  String _getLoadingMessage(String? liveLoadingLabel) {
    if (liveLoadingLabel != null && liveLoadingLabel.isNotEmpty) {
      return liveLoadingLabel;
    }
    switch (_selectedFilter) {
      case 'Shelter':
        return 'Searching for shelters...';
      case 'Food':
        return 'Searching for food...';
      case 'Clinic':
        return 'Searching for clinics...';
      case 'All':
      default:
        return 'Searching for resources...';
    }
  }

  bool _isOpenNow(Resource resource) {
    if (resource.openNow) return true;
    final hours = resource.openingHours.toLowerCase();
    return hours.contains('open 24 hours') ||
        hours.contains('24 hours open') ||
        hours.contains('open 24/7') ||
        hours.contains('24/7');
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
                  _buildProfileOption(
                    Icons.offline_pin_outlined,
                    'Offline Saved',
                    () {
                      Navigator.pushNamed(context, '/offline-saved');
                    },
                  ),
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

  Widget _buildProfileOption(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFF48A8A)),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
