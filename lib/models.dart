class Resource {
  final String id;
  final String name;
  final String type; // e.g. shelter, clinic, food, mental_health
  final String address;
  final String openingHours;
  final bool openNow;
  final bool walkIn;
  final bool appointmentRequired;
  final bool idRequired;
  final String cost; // free, low-cost, paid, unknown
  final bool familiesWelcome;
  final bool womenOnly;
  final bool youthFriendly;
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
    this.openingHours = '',
    this.openNow = false,
    this.walkIn = false,
    this.appointmentRequired = false,
    this.idRequired = false,
    this.cost = 'unknown',
    this.familiesWelcome = false,
    this.womenOnly = false,
    this.youthFriendly = false,
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
      openingHours: data['opening_hours'] ?? data['openingHours'] ?? '',
      openNow: data['open_now'] ?? data['openNow'] ?? false,
      walkIn: data['walk_in'] ?? data['walkIn'] ?? false,
      appointmentRequired:
          data['appointment_required'] ?? data['appointmentRequired'] ?? false,
      idRequired: data['id_required'] ?? data['idRequired'] ?? false,
      cost: (data['cost'] ?? 'unknown').toString(),
      familiesWelcome:
          data['families_welcome'] ?? data['familiesWelcome'] ?? false,
      womenOnly: data['women_only'] ?? data['womenOnly'] ?? false,
      youthFriendly: data['youth_friendly'] ?? data['youthFriendly'] ?? false,
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
      'opening_hours': openingHours,
      'open_now': openNow,
      'walk_in': walkIn,
      'appointment_required': appointmentRequired,
      'id_required': idRequired,
      'cost': cost,
      'families_welcome': familiesWelcome,
      'women_only': womenOnly,
      'youth_friendly': youthFriendly,
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
