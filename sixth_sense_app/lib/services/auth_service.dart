import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message; 
}

class AuthService {
  static final Account _account = AppwriteService.account;

  /// Returns the logged-in user, or null if no session exists.
  static Future<models.User?> getCurrentUser() async {
    try {
      return await _account.get();
    } catch (_) {
      return null;
    }
  }

  static Future<models.User> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      // Log in immediately after account creation
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return await _account.get();
    } on AppwriteException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  static Future<models.User> login({
    required String email,
    required String password,
  }) async {
    try {
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return await _account.get();
    } on AppwriteException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  static Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (_) {
      // ignore - session may already be gone
    }
  }

  static String _friendlyMessage(AppwriteException e) {
    switch (e.type) {
      case 'user_already_exists':
        return 'An account with this email already exists.';
      case 'user_invalid_credentials':
        return 'Incorrect email or password.';
      case 'user_not_found':
        return 'No account found with this email.';
      case 'general_argument_invalid':
        return 'Please check your details and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
