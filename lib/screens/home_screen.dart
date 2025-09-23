import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services.dart';

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
    final primary = const Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Resources' : _tab == 1 ? 'Chat' : 'Profile'),
        backgroundColor: primary,
        actions: [
          IconButton(onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          }, icon: const Icon(Icons.logout))
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _MapAndListTab(service: service),
          const _ChatPlaceholder(),
          _ProfileTab(userEmail: user?.email ?? 'User'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i)=>setState(()=>_tab=i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _MapAndListTab extends StatelessWidget {
  final ResourceService service;
  const _MapAndListTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFF48A8A);
    final filters = ['all', 'shelter', 'food', 'pharmacy', 'clinic'];
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (c, i) {
              final f = filters[i];
              return FilterChip(
                selected: i == 0,
                showCheckmark: false,
                label: Text(f[0].toUpperCase() + f.substring(1)),
                onSelected: (_) {},
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: filters.length,
          ),
        ),
        Expanded(
          flex: 2,
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(40.7128, -74.0060),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sparsh.aidsense',
              ),
              StreamBuilder(
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
          ),
        ),
        Expanded(
          flex: 3,
          child: StreamBuilder(
            stream: service.watchResources(),
            builder: (context, snapshot) {
              final resources = snapshot.data ?? sampleResources;
              return ListView.separated(
                itemCount: resources.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = resources[i];
                  return ListTile(
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(r.address),
                    trailing: Chip(label: Text(r.type)),
                    onTap: () => Navigator.pushNamed(context, '/resource', arguments: r),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChatPlaceholder extends StatelessWidget {
  const _ChatPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Chat coming soon'));
  }
}

class _ProfileTab extends StatelessWidget {
  final String userEmail;
  const _ProfileTab({required this.userEmail});
  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFF48A8A);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const CircleAvatar(radius: 26, child: Icon(Icons.person)),
          title: Text(userEmail),
          subtitle: const Text('Community Member'),
        ),
        const SizedBox(height: 8),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.favorite_border), title: const Text('Favorites'), onTap: () {}),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () {}),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.help_outline), title: const Text('Help Center'), onTap: () {}),
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