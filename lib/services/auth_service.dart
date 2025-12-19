import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email validation
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Password strength validation
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null; // Password is valid
  }

  // Get password strength (0-4)
  int getPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength > 4 ? 4 : strength;
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate email
      if (!isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      // Validate password
      if (password.isEmpty) {
        return {
          'success': false,
          'message': 'Password is required',
        };
      }

      // Firebase sign in
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return {
        'success': true,
        'message': 'Sign in successful',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
          break;
        default:
          message = 'Sign in failed: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // Validate email
      if (!isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      // Validate password
      final passwordError = validatePassword(password);
      if (passwordError != null) {
        return {
          'success': false,
          'message': passwordError,
        };
      }

      // Check if passwords match
      if (password != confirmPassword) {
        return {
          'success': false,
          'message': 'Passwords do not match',
        };
      }

      // Firebase sign up
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return {
        'success': true,
        'message': 'Account created successfully',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        default:
          message = 'Sign up failed: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      if (!isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Password reset email sent',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = 'Failed to send reset email: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}
