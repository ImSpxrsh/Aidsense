import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/firebase/auth_service.dart';
import '../../../core/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit({required AuthService authService})
      : _authService = authService,
        super(const AuthState.initial());

  void checkAuthStatus() {
    if (_authService.isAuthenticated) {
      final user = _authService.currentUser;
      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
          isGuest: user.isAnonymous,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
        );
        emit(AuthState.authenticated(userModel));
      }
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> signInAsGuest() async {
    emit(const AuthState.loading());
    try {
      final user = await _authService.signInAnonymously();
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.error('Failed to sign in as guest'));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(const AuthState.loading());
    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.error('Invalid email or password'));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> createAccount(String email, String password, String displayName) async {
    emit(const AuthState.loading());
    try {
      final user = await _authService.createAccount(email, password, displayName);
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.error('Failed to create account'));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(const AuthState.loading());
    try {
      await _authService.signOut();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      // You might want to show a success message
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }
}
