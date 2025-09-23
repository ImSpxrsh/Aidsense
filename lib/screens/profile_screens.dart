import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: primary),
      body: ListView(children: const [
        SwitchListTile(value: true, onChanged: null, title: Text('Push Notifications')),
        SwitchListTile(value: false, onChanged: null, title: Text('Sounds')),
        SwitchListTile(value: true, onChanged: null, title: Text('Offline Mode')),
      ]),
    );
  }
}

class PasswordManagerScreen extends StatelessWidget {
  const PasswordManagerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFF48A8A);
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Password Manager'), backgroundColor: primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: c1, decoration: const InputDecoration(labelText: 'New Password')),
          const SizedBox(height: 12),
          TextField(controller: c2, decoration: const InputDecoration(labelText: 'Confirm Password')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, child: const Text('Change Password')))
        ]),
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center'), backgroundColor: primary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ExpansionTile(title: Text('Customer Service'), children: [ListTile(title: Text('Email: support@example.com'))]),
          ExpansionTile(title: Text('Privacy Policy'), children: [ListTile(title: Text('Read our policy in app store listing'))]),
          ExpansionTile(title: Text('FAQ'), children: [ListTile(title: Text('How do I reset password?'))]),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), backgroundColor: primary),
      body: ListView.separated(
        itemCount: 8,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.notifications),
          title: Text('Aid Chat #${i + 1}'),
          subtitle: const Text('New message received'),
          onTap: () {},
        ),
      ),
    );
  }
}


