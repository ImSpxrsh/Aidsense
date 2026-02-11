import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../user_data.dart';
import '../models.dart';
import 'chat_screen.dart';
import '../google_maps.dart';
import '../screens/places_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  String userName = 'User';
  String userEmail = 'user@example.com';

  final GlobalKey<_ProfileTabState> _profileKey = GlobalKey<_ProfileTabState>();

  // Shared resource state
  List<Resource> _resources = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNearbyPlaces();
  }

  void _loadUserData() {
    setState(() {
      userName = UserData.fullName;
      userEmail = UserData.email;
    });
  }

  Future<void> _loadNearbyPlaces() async {
    setState(() => _loading = true);
    final location = Location();
    bool enabled = await location.serviceEnabled();
    if (!enabled) {
      enabled = await location.requestService();
      if (!enabled) {
        setState(() => _loading = false);
        return;
      }
    }
    PermissionStatus perm = await location.hasPermission();
    if (perm == PermissionStatus.denied) {
      perm = await location.requestPermission();
      if (perm != PermissionStatus.granted) {
        setState(() => _loading = false);
        return;
      }
    }
    final loc = await location.getLocation();
    if (loc.latitude == null || loc.longitude == null) {
      setState(() => _loading = false);
      return;
    }
    final pos = LatLng(loc.latitude!, loc.longitude!);
    final List<Resource> all = [];
    const categories = ['shelter', 'food', 'clinic', 'Mental Health'];
    final keywordMap = {
      'food': 'food bank soup kitchen',
      'shelter': 'homeless shelter',
      'clinic': 'free clinic community health',
      'Mental Health': 'mental health counseling therapy',
    };
    for (final c in categories) {
      final places = await PlacesService.fetchNearby(
        lat: pos.latitude,
        lng: pos.longitude,
        keyword: keywordMap[c]!,
      );
      final detailedPlaces = await Future.wait(
        places.map((p) => PlacesService.fetchDetails(p)),
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
    }
    setState(() {
      _resources = all;
      _loading = false;
    });
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
                UserData.clearUser();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _MapAndListTab(resources: _resources, loading: _loading),
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
  const _MapAndListTab(
      {Key? key, required this.resources, required this.loading})
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
            initialPosition: _filteredPlaces.isNotEmpty
                ? LatLng(_filteredPlaces.first.latitude,
                    _filteredPlaces.first.longitude)
                : null,
          ),
        ),
        Expanded(
          flex: 2,
          child: widget.loading
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
                                Text(r.address.isNotEmpty
                                    ? r.address
                                    : 'No address available'),
                                const SizedBox(height: 4),
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
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB6C1), Color(0xFFFFA07A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _showUpdateProfileDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Update Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
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

  void _showUpdateProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: UserData.fullName);
    final phoneController = TextEditingController(text: UserData.mobile);
    final emailController = TextEditingController(text: UserData.email);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Update Profile',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                        'Full Name', nameController, 'Enter your full name'),
                    const SizedBox(height: 16),
                    _buildTextField(
                        'Phone Number', phoneController, 'XXX-XXX-XXXX'),
                    const SizedBox(height: 16),
                    _buildTextField(
                        'Email', emailController, 'example@example.com'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Color(0xFF718096),
                          fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);

                          UserData.updateProfile(
                            fullName: nameController.text.trim(),
                            mobile: phoneController.text.trim(),
                            email: emailController.text.trim(),
                          );

                          await Future.delayed(const Duration(seconds: 1));
                          setState(() => isLoading = false);

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Profile updated successfully!'),
                                  backgroundColor: Colors.green),
                            );
                          }
                          widget.onProfileUpdated();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF56565),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFE53E3E)),
            filled: true,
            fillColor: const Color(0xFFE2E8F0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
