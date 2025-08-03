import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  bool get isGuest => currentUser?.isAnonymous ?? false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      final User? user = result.user;
      
      if (user != null) {
        return UserModel(
          uid: user.uid,
          email: 'guest@aidsense.app',
          isGuest: true,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      
      if (user != null) {
        return UserModel(
          uid: user.uid,
          email: user.email ?? email,
          displayName: user.displayName,
          photoURL: user.photoURL,
          isGuest: false,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }

  Future<UserModel?> createAccount(String email, String password, String? displayName) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      
      if (user != null && displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      if (user != null) {
        return UserModel(
          uid: user.uid,
          email: user.email ?? email,
          displayName: displayName,
          isGuest: false,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('Error creating account: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
}
