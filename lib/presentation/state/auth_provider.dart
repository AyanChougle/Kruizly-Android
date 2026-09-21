import '''package:firebase_auth/firebase_auth.dart''';
import '''package:flutter_riverpod/flutter_riverpod.dart''';
import '''../../data/models/user_model.dart''';
import '''app_providers.dart''';

final firebaseUserStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final authRepo = _ref.read(authRepositoryProvider);
    if (authRepo.currentUser != null) {
      try {
        final profile = await authRepo.getProfile();
        state = AuthState(user: profile);
        return;
      } catch (_) {
        try {
          final profile = await authRepo.syncUserWithBackend();
          state = AuthState(user: profile);
          return;
        } catch (_) {}
      }
    }
    state = const AuthState(user: null);
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _ref.read(authRepositoryProvider).signInWithEmailPassword(email, password);
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> registerWithEmailPassword(
    String email,
    String password,
    String name,
    String? phone,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _ref.read(authRepositoryProvider).registerWithEmailPassword(
            email,
            password,
            name,
            phone,
          );
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _ref.read(authRepositoryProvider).signInWithGoogle();
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _ref.read(authRepositoryProvider).sendPasswordReset(email);
  }

  Future<void> refreshProfile() async {
    try {
      final profile = await _ref.read(authRepositoryProvider).getProfile();
      state = state.copyWith(user: profile);
    } catch (_) {}
  }

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
    state = const AuthState(user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
