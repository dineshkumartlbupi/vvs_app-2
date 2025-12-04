import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vvs_app/screens/auth/modals/auth_modal.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Register new user
  Future<String?> register({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      final uid = userCredential.user!.uid;

      // Add uid and email to userData
      final completeUserData = {
        ...userData,
        'uid': uid,
        'email': email.trim().toLowerCase(),
      };

      // Save to Firestore
      await _firestore.collection('users').doc(uid).set(completeUserData);

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'The password provided is too weak. Please use a stronger password.';
        case 'email-already-in-use':
          return 'An account already exists with this email. Please sign in instead.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled. Please contact support.';
        default:
          return e.message ?? 'Registration failed. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred. Please try again later.';
    }
  }

  // 🔹 Login existing user
  Future<String?> login({
    required LoginRequest logindata,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: logindata.email.trim().toLowerCase(),
        password: logindata.password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email. Please register first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        case 'invalid-credential':
          return 'Invalid email or password. Please check your credentials.';
        default:
          return e.message ?? 'Login failed. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred. Please try again later.';
    }
  }

  // 🔹 Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 🔹 Auth state stream
  Stream<User?> authState() => _auth.authStateChanges();
}
