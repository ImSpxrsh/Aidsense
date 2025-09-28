import 'package:aidsense_app/googles_maps.dart';
import 'package:aidsense_app/mock_resources.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const primary = Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0
            ? 'Resources'
            : _tab == 1
                ? 'Chat'
                : 'Profile'),
        backgroundColor: primary,
        actions: [
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _MapAndListTab(service: service),
          const ChatScreen(),
          _ProfileTab(userEmail: user?.email ?? 'User'),
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
          const Expanded(flex: 2, child: MapPage()),
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
      
                final allResources = (snapshot.data == null || snapshot.data!.isEmpty)
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
      
                  final matchesFilter =
                      _selectedFilter == 'all' || r.type.toLowerCase().contains(_selectedFilter.toLowerCase());
      
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
                                  labelStyle:
                                      TextStyle(color: primary, fontSize: 12),
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
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

class _ProfileTab extends StatelessWidget {
  final String userEmail;
  const _ProfileTab({required this.userEmail});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const CircleAvatar(radius: 26, child: Icon(Icons.person)),
          title: Text(userEmail),
          subtitle: const Text('Community Member'),
        ),
        const SizedBox(height: 8),
        Card(
            child: Column(children: [
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Favorites'),
            onTap: () => Navigator.pushNamed(context, '/favorites'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help Center'),
            onTap: () => Navigator.pushNamed(context, '/help'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ])),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: primary),
          onPressed: () {},
          child: const Text('Update Profile'),
        )
      ],
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