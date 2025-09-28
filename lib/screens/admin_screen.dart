import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import '../services.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResourceService _resourceService = ResourceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
        backgroundColor: primary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Resources'),
            Tab(icon: Icon(Icons.add), text: 'Add New'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ResourceListTab(resourceService: _resourceService),
          _AddResourceTab(resourceService: _resourceService),
          const _AnalyticsTab(),
        ],
      ),
    );
  }
}

class _ResourceListTab extends StatefulWidget {
  final ResourceService resourceService;
  
  const _ResourceListTab({required this.resourceService});

  @override
  State<_ResourceListTab> createState() => _ResourceListTabState();
}

class _ResourceListTabState extends State<_ResourceListTab> {
  String _searchQuery = '';
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    final filters = ['all', 'shelter', 'food', 'pharmacy', 'clinic'];

    return Column(
      children: [
        // Search and Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search resources...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    return FilterChip(
                      selected: _selectedFilter == filter,
                      label: Text(filter[0].toUpperCase() + filter.substring(1)),
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: filters.length,
                ),
              ),
            ],
          ),
        ),
        // Resource List
        Expanded(
          child: StreamBuilder<List<Resource>>(
            stream: widget.resourceService.watchResources(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
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

              final allResources = snapshot.data ?? sampleResources;
              
              // Filter resources
              final filteredResources = allResources.where((r) {
                final matchesSearch = _searchQuery.isEmpty || 
                  r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  r.address.toLowerCase().contains(_searchQuery.toLowerCase());
                
                final matchesFilter = _selectedFilter == 'all' || r.type == _selectedFilter;
                
                return matchesSearch && matchesFilter;
              }).toList();

              if (filteredResources.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No resources found'),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: filteredResources.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final resource = filteredResources[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primary.withValues(alpha: 0.1),
                      child: Icon(
                        _getResourceIcon(resource.type),
                        color: primary,
                      ),
                    ),
                    title: Text(resource.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resource.address),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(resource.type),
                              backgroundColor: primary.withValues(alpha: 0.1),
                              labelStyle: TextStyle(color: primary, fontSize: 12),
                            ),
                            if (resource.tags.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(resource.tags.first),
                                backgroundColor: Colors.grey[200],
                                labelStyle: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editResource(resource);
                        } else if (value == 'delete') {
                          _deleteResource(resource);
                        }
                      },
                    ),
                    onTap: () => _viewResource(resource),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _viewResource(Resource resource) {
    Navigator.pushNamed(context, '/resource', arguments: resource);
  }

  void _editResource(Resource resource) {
    // Navigate to edit form
    showDialog(
      context: context,
      builder: (context) => _ResourceFormDialog(
        resource: resource,
        onSave: (updatedResource) async {
          // TODO: Implement Firebase update
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resource updated successfully!')),
          );
        },
      ),
    );
  }

  void _deleteResource(Resource resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text('Are you sure you want to delete "${resource.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement Firebase delete
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Resource deleted successfully!')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

class _AddResourceTab extends StatefulWidget {
  final ResourceService resourceService;
  
  const _AddResourceTab({required this.resourceService});

  @override
  State<_AddResourceTab> createState() => _AddResourceTabState();
}

class _AddResourceTabState extends State<_AddResourceTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _selectedType = 'shelter';
  bool _isLoading = false;

  final List<String> _resourceTypes = ['shelter', 'food', 'pharmacy', 'clinic'];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF48A8A);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Resource',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Resource Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Resource Type',
                border: OutlineInputBorder(),
              ),
              items: _resourceTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type[0].toUpperCase() + type.substring(1)),
              )).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty == true ? 'Address is required' : null,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => value?.isEmpty == true ? 'Latitude is required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => value?.isEmpty == true ? 'Longitude is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                border: OutlineInputBorder(),
                helperText: 'e.g., 24/7, Women, Emergency',
              ),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _addResource,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Add Resource', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addResource() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final resource = Resource(
        id: '', // Firestore will generate this
        name: _nameController.text.trim(),
        type: _selectedType,
        address: _addressController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        tags: tags,
      );

      // TODO: Add resource to Firestore
      await FirebaseFirestore.instance.collection('resources').add(resource.toMap());

      // Clear form
      _formKey.currentState!.reset();
      _nameController.clear();
      _addressController.clear();
      _phoneController.clear();
      _websiteController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _tagsController.clear();
      setState(() => _selectedType = 'shelter');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding resource: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Stats Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Resources', '42', Icons.location_on, Colors.blue),
              _buildStatCard('Active Users', '1,234', Icons.people, Colors.green),
              _buildStatCard('Chat Sessions', '567', Icons.chat, Colors.orange),
              _buildStatCard('Resources Added', '8', Icons.add_circle, Colors.purple),
            ],
          ),
          const SizedBox(height: 32),
          
          // Resource Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resource Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildResourceTypeRow('Shelter', 12, 42),
                  _buildResourceTypeRow('Food', 18, 42),
                  _buildResourceTypeRow('Pharmacy', 8, 42),
                  _buildResourceTypeRow('Clinic', 4, 42),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem('New resource added: Food Bank NYC', '2 hours ago'),
                  _buildActivityItem('User requested shelter information', '4 hours ago'),
                  _buildActivityItem('Resource updated: MediCure Pharmacy', '1 day ago'),
                  _buildActivityItem('New user registered', '2 days ago'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTypeRow(String type, int count, int total) {
    final percentage = (count / total * 100).round();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(type, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: count / total,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF48A8A)),
            ),
          ),
          const SizedBox(width: 12),
          Text('$count ($percentage%)', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 4,
            backgroundColor: Color(0xFFF48A8A),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(activity, style: const TextStyle(fontSize: 14)),
          ),
          Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ResourceFormDialog extends StatefulWidget {
  final Resource? resource;
  final Function(Resource) onSave;

  const _ResourceFormDialog({this.resource, required this.onSave});

  @override
  State<_ResourceFormDialog> createState() => _ResourceFormDialogState();
}

class _ResourceFormDialogState extends State<_ResourceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.resource?.name ?? '');
    _addressController = TextEditingController(text: widget.resource?.address ?? '');
    _phoneController = TextEditingController(text: widget.resource?.phone ?? '');
    _websiteController = TextEditingController(text: widget.resource?.website ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.resource == null ? 'Add Resource' : 'Edit Resource'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Create updated resource
              final updatedResource = Resource(
                id: widget.resource?.id ?? '',
                name: _nameController.text,
                type: widget.resource?.type ?? 'other',
                address: _addressController.text,
                latitude: widget.resource?.latitude ?? 0.0,
                longitude: widget.resource?.longitude ?? 0.0,
                tags: widget.resource?.tags ?? [],
                phone: _phoneController.text,
                website: _websiteController.text,
              );
              widget.onSave(updatedResource);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}