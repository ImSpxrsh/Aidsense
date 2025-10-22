import 'package:aidsense_app/googles_maps.dart';
import 'package:aidsense_app/mock_resources.dart';
import 'package:flutter/material.dart';
import '../user_data.dart';
import '../services.dart';
import '../models.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final service = ResourceService();
  String userName = 'User';
  String userEmail = 'user@example.com';
  final GlobalKey<_ProfileTabState> _profileKey = GlobalKey<_ProfileTabState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      userName = UserData.fullName;
      userEmail = UserData.email;
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
                onPressed: () {
                  setState(() {
                    _tab = 0; // Go back to home/resources tab
                  });
                },
              )
            : null,
        centerTitle: true,
        title: _tab == 1
            ? Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Text(_tab == 0 ? 'Resources' : 'Profile'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          if (_tab == 1)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                // Add menu functionality if needed
              },
            ),
          IconButton(
              onPressed: () async {
                // Show confirmation dialog
                final bool? shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.all(24),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Are you sure you want to log out?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFFF56565)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Color(0xFF2D3748),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF56565),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text(
                                    'Yes, Logout',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );

                if (shouldLogout == true) {
                  UserData.clearUser();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _MapAndListTab(service: service),
          const ChatScreen(),
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
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _MapAndListTab extends StatefulWidget {
  final ResourceService service;
  const _MapAndListTab({required this.service});

  @override
  State<_MapAndListTab> createState() => _MapAndListTabState();
}

class _MapAndListTabState extends State<_MapAndListTab> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  ResourceService get service => widget.service;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    final filters = ['all', 'shelter', 'food', 'pharmacy', 'clinic'];

    return Column(
      children: [
        // Search bar
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

        // Filter chips
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
                label: Text(f[0].toUpperCase() + f.substring(1)),
                onSelected: (_) => setState(() => _selectedFilter = f),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: filters.length,
          ),
        ),
        Expanded(flex: 2, child: MapPage()),

        Expanded(
          flex: 2,
          child: StreamBuilder<List<Resource>>(
            stream: service.watchResources(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Error loading resources: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final allResources =
                  (snapshot.data == null || snapshot.data!.isEmpty)
                      ? mockResources
                      : snapshot.data!;

              // Filter resources based on search and filter
              final filteredResources = allResources.where((r) {
                final matchesSearch = _searchQuery.isEmpty ||
                    r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.address
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    r.tags.any((tag) =>
                        tag.toLowerCase().contains(_searchQuery.toLowerCase()));

                final matchesFilter = _selectedFilter == 'all' ||
                    r.type
                        .toLowerCase()
                        .contains(_selectedFilter.toLowerCase());

                return matchesSearch && matchesFilter;
              }).toList();

              if (filteredResources.isEmpty) {
                return Center(
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
                );
              }

              return ListView.separated(
                itemCount: filteredResources.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = filteredResources[i];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary.withValues(alpha: 0.1),
                        child: Icon(
                          _getResourceIcon(r.type),
                          color: primary,
                        ),
                      ),
                      title: Text(r.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.address),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Chip(
                                label: Text(r.type),
                                backgroundColor: primary.withValues(alpha: 0.1),
                                labelStyle: const TextStyle(
                                    color: primary, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              if (r.tags.isNotEmpty)
                                Chip(
                                  label: Text(r.tags.first),
                                  backgroundColor: Colors.grey[200],
                                  labelStyle: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/resource',
                          arguments: r),
                    ),
                  );
                },
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
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'clinic':
        return Icons.local_hospital;
      default:
        return Icons.location_on;
    }
  }
}

class _ProfileTab extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback? onProfileUpdated;
  const _ProfileTab(
      {super.key,
      required this.userName,
      required this.userEmail,
      this.onProfileUpdated});

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
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 3),
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
          // User Information
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userMobile.isNotEmpty ? userMobile : 'No phone number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
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
                  // Update Profile Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFB6C1), // Light pink
                          Color(0xFFFFA07A), // Salmon pink
                        ],
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
                          fontWeight: FontWeight.bold,
                        ),
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
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
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
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Update Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Full Name',
                          style: TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            hintStyle:
                                const TextStyle(color: Color(0xFFE53E3E)),
                            filled: true,
                            fillColor: const Color(0xFFE2E8F0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Phone Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phone Number',
                          style: TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            hintText: 'XXX-XXX-XXXX',
                            hintStyle:
                                const TextStyle(color: Color(0xFFE53E3E)),
                            filled: true,
                            fillColor: const Color(0xFFE2E8F0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Email Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email',
                          style: TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: 'example@example.com',
                            hintStyle:
                                const TextStyle(color: Color(0xFFE53E3E)),
                            filled: true,
                            fillColor: const Color(0xFFE2E8F0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);

                          // Update user data
                          UserData.updateProfile(
                            fullName: nameController.text.trim(),
                            mobile: phoneController.text.trim(),
                            email: emailController.text.trim(),
                          );

                          // Simulate API call delay
                          await Future.delayed(const Duration(seconds: 1));

                          setState(() => isLoading = false);

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            // Call the callback to refresh the parent
                            widget.onProfileUpdated?.call();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF56565),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


// Old Map
/*FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(40.7128, -74.0060),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sparsh.aidsense',
              ),
              StreamBuilder<List<Resource>>(
                stream: service.watchResources(),
                builder: (context, snapshot) {
                  final resources = snapshot.data ?? sampleResources;
                  return MarkerLayer(
                    markers: resources.map((r) => Marker(
                      point: LatLng(r.latitude, r.longitude),
                      width: 36,
                      height: 36,
                      child: Icon(Icons.location_pin, color: primary, size: 32),
                    )).toList(),
                  );
                },
              )
            ],
          ), */