import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService._privateConstructor();
  static final AuthService _instance = AuthService._privateConstructor();
  factory AuthService() {
    return _instance;
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    // ... (no changes to signIn)
    print("[AuthService] Attempting to sign in user: $email");
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      print("[AuthService] Firebase Auth user SIGNED IN successfully: ${userCredential.user?.uid}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("[AuthService] FIREBASE AUTH EXCEPTION during sign-in: ${e.code} - ${e.message}");
      throw e;
    } catch (e) {
      print("[AuthService] GENERAL EXCEPTION during sign-in: $e");
      throw e;
    }
  }


  // MODIFIED: Now returns bool indicating full success
  Future<bool> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    print("[AuthService] Attempting to register user: $email");
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      print("[AuthService] Firebase Auth user CREATED successfully: ${userCredential.user?.uid}");

      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
      User? updatedUser = _firebaseAuth.currentUser;
      print("[AuthService] User display name updated to: ${updatedUser?.displayName}");

      if (updatedUser != null) {
        print("[AuthService] Attempting to write to Firestore users collection for UID: ${updatedUser.uid}");
        try {
          await _firestore.collection('users').doc(updatedUser.uid).set({
            'uid': updatedUser.uid,
            'email': email,
            'displayName': displayName,
            'createdAt': Timestamp.now(),
            'role': 'user',
          });
          print("[AuthService] Firestore users document CREATED successfully for UID: ${updatedUser.uid}");
          return true; // Full success
        } catch (firestoreError) {
          print("[AuthService] FIRESTORE WRITE ERROR: $firestoreError");
          // Optionally delete auth user here if Firestore write fails
          // await userCredential.user?.delete();
          throw Exception("Failed to save user details to database. $firestoreError");
        }
      } else {
         print("[AuthService] User object was null after displayName update and reload. Cannot write to Firestore.");
         throw Exception("User became null after profile update.");
      }
    } on FirebaseAuthException catch (e) {
      print("[AuthService] FIREBASE AUTH EXCEPTION during registration: ${e.code} - ${e.message}");
      throw e; // Re-throw to be caught by UI
    } catch (e) {
      print("[AuthService] GENERAL EXCEPTION during registration: $e");
      throw e; // Re-throw
    }
    // return false; // Should not be reached if exceptions are thrown
  }

  Future<void> signOut() async {
    // ... (no changes to signOut)
    print("[AuthService] Attempting to sign out.");
    try {
      await _firebaseAuth.signOut();
      print("[AuthService] User signed out successfully.");
    } catch (e) {
      print("[AuthService] Sign-out error: $e");
      throw e;
    }
  }
}