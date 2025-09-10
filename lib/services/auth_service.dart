import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vvs_app/screens/common/modals/auth_modal.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 
  Future<String?> register({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      //Save user data in 'users' collection
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> login({required LoginRequest logindata}) async
  
   {
    print("i am from login service");
    print(logindata.email);
    print(logindata.password);

    try {
      await _auth.signInWithEmailAndPassword(
        email: logindata.email,
        password: logindata.password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> authState() => _auth.authStateChanges();
}
