import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('About AidSense'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connecting people to nearby support.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'AidSense helps people quickly discover local resources such as food support, shelter, clinics, and mental health services using search, maps, and guided assistance.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          _Section(
            'What the app does',
            '• Finds nearby community resources\n• Lets users search by need\n• Shows results on a map\n• Provides a resource details screen\n• Supports account sign-in and profile management\n• Offers an AI assistant for quick guidance',
          ),
          _Section(
            'Who it serves',
            'AidSense is built for people who need fast access to local help and for communities that want a simpler way to connect users with resources.',
          ),
          _Section(
            'Notes',
            'Resource availability can change, so users should verify details before visiting. AI guidance may sometimes be incomplete or incorrect and should not be treated as professional, legal, or emergency advice. The app focuses on helping people discover support quickly and with less friction.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB71C1C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}
