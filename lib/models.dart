class Resource {
  final String id;
  final String name;
  final String type; // e.g. shelter, clinic, food, mental_health
  final String address;
  final double latitude;
  final double longitude;
  final List<String> tags;
  final String phone;
  final String website;

  Resource({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.tags,
    required this.phone,
    required this.website,
  });

  factory Resource.fromMap(String id, Map<String, dynamic> data) {
    return Resource(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'other',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      phone: data['phone'] ?? '',
      website: data['website'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
      'phone': phone,
      'website': website,
    };
  }
}

class UserProfile {
  final String uid;
  final String fullName;
  final String phone;
  final String email;
  final List<String> favorites; // resource ids

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.favorites,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      favorites:
          (data['favorites'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'favorites': favorites,
    };
  }
}
