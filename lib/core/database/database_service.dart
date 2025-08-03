import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/service_model.dart';
import '../models/bookmark_model.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'aidsense.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _servicesTable = 'services';
  static const String _bookmarksTable = 'bookmarks';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create services table
    await db.execute('''
      CREATE TABLE $_servicesTable(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        hotline TEXT,
        street TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        zipCode TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        website TEXT,
        notes TEXT,
        eligibilityRequirements TEXT,
        documentsNeeded TEXT,
        isEmergency INTEGER DEFAULT 0,
        rating REAL,
        lastUpdated TEXT,
        operatingHours TEXT
      )
    ''');

    // Create bookmarks table
    await db.execute('''
      CREATE TABLE $_bookmarksTable(
        id TEXT PRIMARY KEY,
        serviceId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        notes TEXT,
        tags TEXT,
        FOREIGN KEY (serviceId) REFERENCES $_servicesTable (id)
      )
    ''');

    // Create indexes for better search performance
    await db.execute('CREATE INDEX idx_services_category ON $_servicesTable(category)');
    await db.execute('CREATE INDEX idx_services_zipcode ON $_servicesTable(zipCode)');
    await db.execute('CREATE INDEX idx_services_emergency ON $_servicesTable(isEmergency)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  /// Insert or update a service
  Future<void> insertService(ServiceModel service) async {
    final db = await database;
    await db.insert(
      _servicesTable,
      _serviceToMap(service),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple services (for bulk loading)
  Future<void> insertServices(List<ServiceModel> services) async {
    final db = await database;
    final batch = db.batch();
    
    for (final service in services) {
      batch.insert(
        _servicesTable,
        _serviceToMap(service),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  /// Search services by category and location
  Future<List<ServiceModel>> searchServices({
    List<String>? categories,
    String? zipCode,
    double? latitude,
    double? longitude,
    double? radiusInMiles,
    bool? isEmergency,
    int limit = 50,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Build WHERE clause
    List<String> conditions = [];

    if (categories != null && categories.isNotEmpty) {
      String categoryPlaceholders = categories.map((_) => '?').join(',');
      conditions.add('category IN ($categoryPlaceholders)');
      whereArgs.addAll(categories);
    }

    if (zipCode != null) {
      conditions.add('zipCode = ?');
      whereArgs.add(zipCode);
    }

    if (isEmergency != null) {
      conditions.add('isEmergency = ?');
      whereArgs.add(isEmergency ? 1 : 0);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    String orderBy = 'ORDER BY name ASC LIMIT $limit';

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $_servicesTable 
      $whereClause 
      $orderBy
    ''', whereArgs);

    return maps.map((map) => _serviceFromMap(map)).toList();
  }

  /// Get all services
  Future<List<ServiceModel>> getAllServices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_servicesTable);
    return maps.map((map) => _serviceFromMap(map)).toList();
  }

  /// Add bookmark
  Future<void> addBookmark(BookmarkModel bookmark) async {
    final db = await database;
    await db.insert(
      _bookmarksTable,
      _bookmarkToMap(bookmark),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove bookmark
  Future<void> removeBookmark(String bookmarkId) async {
    final db = await database;
    await db.delete(
      _bookmarksTable,
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
  }

  /// Get all bookmarks with service details
  Future<List<BookmarkModel>> getBookmarks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, s.* FROM $_bookmarksTable b
      JOIN $_servicesTable s ON b.serviceId = s.id
      ORDER BY b.createdAt DESC
    ''');

    return maps.map((map) => _bookmarkFromMapWithService(map)).toList();
  }

  /// Check if service is bookmarked
  Future<bool> isServiceBookmarked(String serviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      _bookmarksTable,
      where: 'serviceId = ?',
      whereArgs: [serviceId],
    );
    return result.isNotEmpty;
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_servicesTable);
    await db.delete(_bookmarksTable);
  }

  // Helper methods for converting between objects and maps
  Map<String, dynamic> _serviceToMap(ServiceModel service) {
    return {
      'id': service.id,
      'name': service.name,
      'description': service.description,
      'category': service.category.name,
      'phone': service.contactInfo.phone,
      'email': service.contactInfo.email,
      'hotline': service.contactInfo.hotline,
      'street': service.address.street,
      'city': service.address.city,
      'state': service.address.state,
      'zipCode': service.address.zipCode,
      'latitude': service.address.latitude,
      'longitude': service.address.longitude,
      'website': service.website,
      'notes': service.notes,
      'eligibilityRequirements': service.eligibilityRequirements?.join('|'),
      'documentsNeeded': service.documentsNeeded?.join('|'),
      'isEmergency': service.isEmergency == true ? 1 : 0,
      'rating': service.rating,
      'lastUpdated': service.lastUpdated?.toIso8601String(),
      'operatingHours': service.operatingHours.toJson().toString(),
    };
  }

  ServiceModel _serviceFromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: ServiceCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ServiceCategory.emergency,
      ),
      contactInfo: ContactInfo(
        phone: map['phone'],
        email: map['email'],
        hotline: map['hotline'],
      ),
      address: Address(
        street: map['street'],
        city: map['city'],
        state: map['state'],
        zipCode: map['zipCode'],
        latitude: map['latitude'],
        longitude: map['longitude'],
      ),
      operatingHours: OperatingHours(), // TODO: Parse from JSON
      website: map['website'],
      notes: map['notes'],
      eligibilityRequirements: map['eligibilityRequirements']?.split('|'),
      documentsNeeded: map['documentsNeeded']?.split('|'),
      isEmergency: map['isEmergency'] == 1,
      rating: map['rating'],
      lastUpdated: map['lastUpdated'] != null 
          ? DateTime.parse(map['lastUpdated'])
          : null,
    );
  }

  Map<String, dynamic> _bookmarkToMap(BookmarkModel bookmark) {
    return {
      'id': bookmark.id,
      'serviceId': bookmark.serviceId,
      'createdAt': bookmark.createdAt.toIso8601String(),
      'notes': bookmark.notes,
      'tags': bookmark.tags?.join('|'),
    };
  }

  BookmarkModel _bookmarkFromMapWithService(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'],
      serviceId: map['serviceId'],
      service: _serviceFromMap(map),
      createdAt: DateTime.parse(map['createdAt']),
      notes: map['notes'],
      tags: map['tags']?.split('|'),
    );
  }
}
