import 'package:flutter/material.dart';
import '../models.dart';

class ResourceDetailScreen extends StatelessWidget {
  const ResourceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Resource r = ModalRoute.of(context)!.settings.arguments as Resource;
    final primary = const Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(title: Text(r.name), backgroundColor: primary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.map, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(r.address, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: r.tags.map((t) => Chip(label: Text(t))).toList()),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening directions...')),
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
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to favorites!')),
                  );
                },
                icon: const Icon(Icons.favorite),
                label: const Text('Favorite'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}


