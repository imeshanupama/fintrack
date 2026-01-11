import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Gracefully handle missing Firebase config
  try {
    return AuthRepository(FirebaseAuth.instance);
  } catch (e) {
    return AuthRepository(null);
  }
});

class AuthRepository {
  final FirebaseAuth? _auth;

  AuthRepository(this._auth);

  Stream<User?> get authStateChanges {
    return _auth?.userChanges() ?? Stream.value(null);
  }

  User? get currentUser => _auth?.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    if (_auth == null) throw Exception("Firebase not initialized. Add config files.");
    return await _auth!.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password) async {
    if (_auth == null) throw Exception("Firebase not initialized. Add config files.");
    return await _auth!.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    if (_auth == null) throw Exception("Firebase not initialized. Add config files.");
    await _googleSignIn.signOut(); // Ensure Google also signs out
    await _auth!.signOut();
  }

  // Google Sign-In
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> signInWithGoogle() async {
    if (_auth == null) throw Exception("Firebase not initialized. Add config files.");

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception("Google Sign-In aborted");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth!.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDisplayName(String name) async {
    if (_auth == null || _auth!.currentUser == null) return;
    await _auth!.currentUser!.updateDisplayName(name);
    await _auth!.currentUser!.reload();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (_auth == null) throw Exception("Firebase not initialized.");
    await _auth!.sendPasswordResetEmail(email: email);
  }
}
