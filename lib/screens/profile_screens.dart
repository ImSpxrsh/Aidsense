import 'package:flutter/material.dart';
import 'resource_detail_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';
import 'polyline_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _zipCodeController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current user data (in a real app, you'd load from Firebase/storage)
    _fullNameController.text = 'Current User'; // Placeholder
    _emailController.text = 'user@example.com'; // Placeholder
    _phoneController.text = ''; // Placeholder
    _zipCodeController.text = '07302'; // Default Jersey City zip
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);

    try {
      // In a real app, you'd save to Firebase/backend here
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Change Profile Photo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _photoOption(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          onTap: () {
                            Navigator.pop(context);
                            _takePicture();
                          },
                        ),
                        _photoOption(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onTap: () {
                            Navigator.pop(context);
                            _selectFromGallery();
                          },
                        ),
                        _photoOption(
                          icon: Icons.delete,
                          label: 'Remove',
                          onTap: () {
                            Navigator.pop(context);
                            _removePhoto();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1E88E5),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _takePicture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📸 Camera functionality will be available soon'),
        backgroundColor: Color(0xFF1E88E5),
      ),
    );
  }

  void _selectFromGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖼️ Gallery selection will be available soon'),
        backgroundColor: Color(0xFF1E88E5),
      ),
    );
  }

  void _removePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Photo removed successfully'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFFB71C1C),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[600],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showPhotoOptions,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap camera to change photo',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Form Fields
            _buildInputField(
              label: 'Full Name',
              controller: _fullNameController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'Email Address',
              controller: _emailController,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'Zip Code',
              controller: _zipCodeController,
              icon: Icons.location_on_outlined,
              keyboardType: TextInputType.number,
              helpText: 'Used to find nearby resources',
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            helpText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _sounds = false;
  bool _offlineMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // In a real app, you'd use SharedPreferences here
    // For now, just using default values
    setState(() {
      _pushNotifications = true;
      _sounds = false;
      _offlineMode = true;
    });
  }

  Future<void> _saveSettings() async {
    // In a real app, you'd save to SharedPreferences here
    // For now, just show a confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: primary),
      body: ListView(children: [
        // Profile Section
        ListTile(
          leading: const Icon(Icons.person_outline, color: primary),
          title: const Text('Edit Profile'),
          subtitle: const Text('Update your personal information and zip code'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen()),
            );
          },
        ),
        const Divider(),

        // Settings Section
        SwitchListTile(
          value: _pushNotifications,
          onChanged: (value) {
            setState(() => _pushNotifications = value);
            _saveSettings();
          },
          title: const Text('Push Notifications'),
          subtitle: Text(_pushNotifications ? 'Enabled' : 'Disabled'),
          secondary: Icon(
            _pushNotifications ? Icons.notifications : Icons.notifications_off,
            color: primary,
          ),
        ),
        SwitchListTile(
          value: _sounds,
          onChanged: (value) {
            setState(() => _sounds = value);
            _saveSettings();
          },
          title: const Text('Sounds'),
          subtitle: Text(_sounds ? 'Enabled' : 'Disabled'),
          secondary: Icon(
            _sounds ? Icons.volume_up : Icons.volume_off,
            color: primary,
          ),
        ),
        SwitchListTile(
          value: _offlineMode,
          onChanged: (value) {
            setState(() => _offlineMode = value);
            _saveSettings();
          },
          title: const Text('Offline Mode'),
          subtitle: Text(
              _offlineMode ? 'Cache resources locally' : 'Requires internet'),
          secondary: Icon(
            _offlineMode ? Icons.cloud_off : Icons.cloud,
            color: primary,
          ),
        ),
      ]),
    );
  }
}

class PasswordManagerScreen extends StatelessWidget {
  const PasswordManagerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Password Manager'), backgroundColor: primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
              controller: c1,
              decoration: const InputDecoration(labelText: 'New Password')),
          const SizedBox(height: 12),
          TextField(
              controller: c2,
              decoration: const InputDecoration(labelText: 'Confirm Password')),
          const SizedBox(height: 16),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {}, child: const Text('Change Password')))
        ]),
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    return Scaffold(
      appBar:
          AppBar(title: const Text('Help Center'), backgroundColor: primary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Actions Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need immediate help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB71C1C),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Call our 24/7 support line: (201) 555-0123'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Live Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.email, size: 16),
                        label: const Text('Email Us'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: const BorderSide(color: primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Legal Documents
          ListTile(
            leading: const Icon(Icons.description, color: primary),
            title: const Text('Terms of Service'),
            subtitle: const Text('View our terms and conditions'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TermsOfServiceScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security, color: primary),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How we protect your information'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const Divider(),

          // FAQ Section
          ExpansionTile(
            leading: const Icon(Icons.help_outline, color: primary),
            title: const Text('Frequently Asked Questions'),
            children: [
              _buildFAQItem(
                'How do I find resources near me?',
                'Enable location services and use the map or search feature. You can also update your zip code in profile settings.',
              ),
              _buildFAQItem(
                'Is AidSense free to use?',
                'Yes! AidSense is completely free for all users. We believe everyone deserves access to community resources.',
              ),
              _buildFAQItem(
                'How do I reset my password?',
                'Go to the login screen and tap "Forgot Password". Enter your email to receive a reset link.',
              ),
              _buildFAQItem(
                'Can I use AidSense without creating an account?',
                'You can browse resources without an account, but creating one allows you to save favorites and get personalized recommendations.',
              ),
              _buildFAQItem(
                'How often is resource information updated?',
                'We update resource information weekly and work with local organizations to ensure accuracy.',
              ),
              _buildFAQItem(
                'What if a resource location is closed or incorrect?',
                'Please report incorrect information through the app or email us at support@aidsense.com. We\'ll investigate and update it.',
              ),
            ],
          ),

          // Account Help
          ExpansionTile(
            leading: const Icon(Icons.account_circle, color: primary),
            title: const Text('Account & Profile'),
            children: [
              _buildFAQItem(
                'How do I update my profile information?',
                'Go to Settings > Edit Profile to update your name, email, phone number, and zip code.',
              ),
              _buildFAQItem(
                'Can I delete my account?',
                'Yes, contact us at support@aidsense.com to permanently delete your account and all associated data.',
              ),
              _buildFAQItem(
                'How do I change my notification settings?',
                'Go to Settings and toggle push notifications, sounds, or offline mode as needed.',
              ),
            ],
          ),

          // Technical Support
          ExpansionTile(
            leading: const Icon(Icons.build, color: primary),
            title: const Text('Technical Support'),
            children: [
              _buildFAQItem(
                'The app is running slowly',
                'Try closing and reopening the app. If problems persist, restart your device or update to the latest version.',
              ),
              _buildFAQItem(
                'Location services aren\'t working',
                'Check that location permissions are enabled in your device settings for AidSense.',
              ),
              _buildFAQItem(
                'I\'m not receiving notifications',
                'Check notification permissions in device settings and ensure they\'re enabled in the app settings.',
              ),
            ],
          ),

          // Contact Information
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text('📧 Email: support@aidsense.com'),
                Text('📞 Phone: (201) 555-0123'),
                Text('📍 Address: 123 Community Way, Jersey City, NJ 07302'),
                SizedBox(height: 8),
                Text(
                  'Business Hours: Monday-Friday 9AM-6PM EST',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Favorites'),
          backgroundColor: primary,
          titleTextStyle: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          iconTheme: const IconThemeData(color: Colors.white)),
      body: AnimatedBuilder(
        animation: FavoritesService(),
        builder: (context, _) {
          final favorites = FavoritesService().favorites;
          if (favorites.isEmpty) {
            return const Center(child: Text('No favorites yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final r = favorites[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      r.type == 'Pharmacy'
                          ? Icons.local_pharmacy
                          : r.type == 'Shelter'
                              ? Icons.home
                              : Icons.restaurant,
                    ),
                  ),
                  title: Text(r.name),
                  subtitle: Text(r.address),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.directions),
                        onPressed: () async {
                          final polylineService = PolylineService();
                          final markers =
                              await polylineService.createMarkers(r);
                          final polylines =
                              await polylineService.getPolyline(r);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DirectionsMapScreen(
                                markers: markers,
                                polylines: polylines,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: FavoritesService().isFavorite(r)
                              ? Colors.red
                              : Colors.grey,
                        ),
                        onPressed: () {
                          final nowAdded = FavoritesService().isFavorite(r);
                          FavoritesService().toggleFavorite(r);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                nowAdded
                                    ? 'Removed from favorites!'
                                    : 'Added to favorites!',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> notifications = [
    NotificationItem(
      id: '1',
      title: 'New Resource Added',
      message: 'A new food bank has been added near your area',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      type: NotificationType.resource,
    ),
    NotificationItem(
      id: '2',
      title: 'Chat Response',
      message: 'AI Assistant has suggestions for your shelter request',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
      type: NotificationType.chat,
    ),
    NotificationItem(
      id: '3',
      title: 'Profile Updated',
      message: 'Your profile information has been successfully updated',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      type: NotificationType.system,
    ),
    NotificationItem(
      id: '4',
      title: 'Resource Hours Changed',
      message: 'Mount Pisgah Food Pantry has updated their hours',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.resource,
    ),
    NotificationItem(
      id: '5',
      title: 'Welcome to AidSense!',
      message:
          'Thank you for joining our community. Start exploring resources now.',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      type: NotificationType.welcome,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
        backgroundColor: primary,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark All Read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'We\'ll notify you about new resources and updates',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      notifications.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${notification.title} deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            setState(() {
                              notifications.insert(index, notification);
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: notification.isRead ? Colors.white : Colors.blue[50],
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            notification.isRead ? Colors.grey[300] : primary,
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: notification.isRead
                              ? Colors.grey[600]
                              : Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.message),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(notification.time),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () => _handleNotificationTap(notification),
                      trailing: !notification.isRead
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return Icons.chat;
      case NotificationType.resource:
        return Icons.location_on;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.welcome:
        return Icons.waving_hand;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    setState(() {
      notification.isRead = true;
    });

    switch (notification.type) {
      case NotificationType.chat:
        Navigator.pushNamed(context, '/home'); // Navigate to chat
        break;
      case NotificationType.resource:
        Navigator.pushNamed(context, '/home'); // Navigate to resources
        break;
      case NotificationType.system:
        Navigator.pushNamed(context, '/settings');
        break;
      case NotificationType.welcome:
        Navigator.pushNamed(context, '/home');
        break;
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });
}

enum NotificationType {
  chat,
  resource,
  system,
  welcome,
}
