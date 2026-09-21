import '''package:firebase_auth/firebase_auth.dart''';
import '''package:google_sign_in/google_sign_in.dart''';
import '''../../core/constants/api_endpoints.dart''';
import '''../../core/errors/app_exceptions.dart''';
import '''../../core/network/api_client.dart''';
import '''../models/user_model.dart''';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user == null) {
        throw const AuthException('''Sign-in failed. Please try again.''');
      }
      return await syncUserWithBackend(name: cred.user?.displayName);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<UserModel> registerWithEmailPassword(
    String email,
    String password,
    String name,
    String? phone,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        await cred.user!.updateDisplayName(name.trim());
      }
      return await syncUserWithBackend(name: name.trim(), phone: phone?.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      return await syncUserWithBackend(name: userCred.user?.displayName);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      final err = e.toString();
      if (err.contains('ApiException: 10') ||
          err.contains('12500') ||
          err.contains('DEVELOPER_ERROR')) {
        throw const AuthException(
          'Google Sign-In configuration pending: Your Android debug certificate fingerprint (SHA-1) needs to be registered in the Firebase Console under project "carrentpeweb". Please use Email / Password or explore as Guest in the meantime.',
        );
      }
      throw AppException(e.toString());
    }
  }

  Future<UserModel> syncUserWithBackend({
    String? name,
    String? phone,
    int? age,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('''No user signed in to synchronize.''');
    }

    try {
      final response = await _apiClient.post(
        ApiEndpoints.usersSync,
        data: {
          '''name''': name ?? user.displayName ?? '''User''',
          '''phone''': ?phone,
          '''age''': ?age,
        },
      );
      if (response is Map<String, dynamic> && response['''user'''] != null) {
        return UserModel.fromJson(response['''user''']);
      }
      return await getProfile();
    } catch (_) {
      return await getProfile();
    }
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.usersMe);
    if (response is Map<String, dynamic> && response['''user'''] != null) {
      return UserModel.fromJson(response['''user''']);
    }
    throw const ServerException('''Failed to load user profile.''');
  }

  Future<UserModel> updateProfile({
    required String name,
    String? phone,
    int? age,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.usersMe,
      data: {'''name''': name, '''phone''': ?phone, '''age''': ?age},
    );
    if (response is Map<String, dynamic>) {
      return await getProfile();
    }
    throw const ServerException('''Failed to update profile.''');
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case '''user-not-found''':
      case '''wrong-password''':
      case '''invalid-credential''':
        return '''Invalid email or password. Please verify your credentials.''';
      case '''email-already-in-use''':
        return '''An account with this email already exists. Please sign in instead.''';
      case '''weak-password''':
        return '''Password must be at least 6 characters.''';
      case '''invalid-email''':
        return '''Please enter a valid email address.''';
      default:
        return e.message ?? '''Authentication failed. Please try again.''';
    }
  }
}
