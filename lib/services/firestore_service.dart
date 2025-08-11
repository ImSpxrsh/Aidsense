import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';
import '../models/bookmark_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get placesCollection => _firestore.collection('places');
  CollectionReference get bookmarksCollection => _firestore.collection('bookmarks');
  CollectionReference get usersCollection => _firestore.collection('users');

  // Places operations
  Future<List<PlaceModel>> searchPlaces({
    String? query,
    List<PlaceCategory>? categories,
    String? zipCode,
    double? latitude,
    double? longitude,
    int limit = 20,
  }) async {
    try {
      Query queryRef = placesCollection;

      // Filter by categories if provided
      if (categories != null && categories.isNotEmpty) {
        queryRef = queryRef.where('category', whereIn: categories.map((c) => c.name).toList());
      }

      // Filter by zip code if provided (for NJ-09 area)
      if (zipCode != null) {
        queryRef = queryRef.where('address.zipCode', isEqualTo: zipCode);
      }

      // Add text search capabilities would require additional setup
      // For now, we'll use basic queries and filter client-side if needed

      queryRef = queryRef.limit(limit);

      final QuerySnapshot snapshot = await queryRef.get();
      
      return snapshot.docs
          .map((doc) => PlaceModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  Future<PlaceModel?> getPlace(String placeId) async {
    try {
      final DocumentSnapshot doc = await placesCollection.doc(placeId).get();
      if (doc.exists) {
        return PlaceModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      print('Error getting place: $e');
      return null;
    }
  }

  Future<void> addPlace(PlaceModel place) async {
    try {
      await placesCollection.doc(place.id).set(place.toJson());
    } catch (e) {
      print('Error adding place: $e');
      rethrow;
    }
  }

  Future<void> updatePlace(PlaceModel place) async {
    try {
      await placesCollection.doc(place.id).update(place.toJson());
    } catch (e) {
      print('Error updating place: $e');
      rethrow;
    }
  }

  // Bookmark operations
  Future<void> addBookmark(BookmarkModel bookmark) async {
    try {
      await bookmarksCollection.doc(bookmark.id).set(bookmark.toJson());
    } catch (e) {
      print('Error adding bookmark: $e');
      rethrow;
    }
  }

  Future<void> removeBookmark(String bookmarkId) async {
    try {
      await bookmarksCollection.doc(bookmarkId).delete();
    } catch (e) {
      print('Error removing bookmark: $e');
      rethrow;
    }
  }

  Future<List<BookmarkModel>> getUserBookmarks(String userId) async {
    try {
      final QuerySnapshot snapshot = await bookmarksCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<BookmarkModel> bookmarks = [];
      
      for (var doc in snapshot.docs) {
        final bookmarkData = doc.data() as Map<String, dynamic>;
        final placeId = bookmarkData['placeId'];
        
        // Fetch the place details
        final place = await getPlace(placeId);
        if (place != null) {
          bookmarks.add(BookmarkModel.fromJson({
            'id': doc.id,
            'place': place.toJson(),
            ...bookmarkData,
          }));
        }
      }
      
      return bookmarks;
    } catch (e) {
      print('Error getting user bookmarks: $e');
      return [];
    }
  }

  Future<bool> isPlaceBookmarked(String userId, String placeId) async {
    try {
      final QuerySnapshot snapshot = await bookmarksCollection
          .where('userId', isEqualTo: userId)
          .where('placeId', isEqualTo: placeId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking bookmark status: $e');
      return false;
    }
  }

  // User operations
  Future<void> saveUserData(UserModel user) async {
    try {
      await usersCollection.doc(user.uid).set(user.toJson());
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson({
          'uid': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // NJ-09 specific queries
  Future<List<PlaceModel>> getNJ09Places({PlaceCategory? category}) async {
    try {
      // NJ-09 zip codes (partial list - you'd want to include all)
      const nj09ZipCodes = [
        '07002', '07008', '07014', '07020', '07022', '07024', '07030', 
        '07031', '07032', '07036', '07047', '07055', '07057', '07070', 
        '07080', '07086', '07087', '07093', '07094', '07095'
      ];

      Query queryRef = placesCollection.where('address.zipCode', whereIn: nj09ZipCodes);

      if (category != null) {
        queryRef = queryRef.where('category', isEqualTo: category.name);
      }

      final QuerySnapshot snapshot = await queryRef.get();
      
      return snapshot.docs
          .map((doc) => PlaceModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      print('Error getting NJ-09 places: $e');
      return [];
    }
  }
}
