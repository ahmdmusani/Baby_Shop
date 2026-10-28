import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ─── LOGIN (Bina Kisi Blocking Check Ke) ──────────────────────────────────
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      // Direct Firebase Auth verification
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected login error occurred.';
    }
  }

  // ─── GOOGLE SIGN-IN ────────────────────────────────────────────────────────
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw 'Google Sign-In cancelled by user.';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await saveSocialUserToFirestore(
          uid: userCredential.user!.uid,
          fullName: userCredential.user!.displayName ?? googleUser.displayName ?? 'Google User',
          email: userCredential.user!.email ?? googleUser.email,
          photoUrl: userCredential.user!.photoURL ?? googleUser.photoUrl,
          provider: 'google',
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('sign_in_failed') || e.toString().contains('cancelled')) {
        throw 'Google Sign-In cancelled or failed.';
      }
      throw e.toString();
    }
  }

  // ─── FACEBOOK LOGIN ────────────────────────────────────────────────────────
  Future<UserCredential> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.token);
        final userCredential = await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          // Retrieve Facebook user details if available
          final userData = await FacebookAuth.instance.getUserData();
          final String name = userData['name'] ?? userCredential.user!.displayName ?? 'Facebook User';
          final String email = userData['email'] ?? userCredential.user!.email ?? '';
          final String? photoUrl = userData['picture']?['data']?['url'] ?? userCredential.user!.photoURL;

          await saveSocialUserToFirestore(
            uid: userCredential.user!.uid,
            fullName: name,
            email: email,
            photoUrl: photoUrl,
            provider: 'facebook',
          );
        }
        return userCredential;
      } else if (result.status == LoginStatus.cancelled) {
        throw 'Facebook Login cancelled by user.';
      } else {
        throw result.message ?? 'Facebook Login failed.';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // ─── APPLE SIGN-IN ─────────────────────────────────────────────────────────
  Future<UserCredential> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: null,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        String fullName = 'Apple User';
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          fullName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        } else if (userCredential.user!.displayName != null) {
          fullName = userCredential.user!.displayName!;
        }

        await saveSocialUserToFirestore(
          uid: userCredential.user!.uid,
          fullName: fullName,
          email: userCredential.user!.email ?? appleCredential.email ?? '',
          provider: 'apple',
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('SignInWithAppleAuthorizationError') || e.toString().contains('cancelled')) {
        throw 'Apple Sign-In cancelled by user.';
      }
      throw e.toString();
    }
  }

  // ─── SOCIAL SIGN-IN FALLBACK (FOR WEB/EMULATORS) ───────────────────────────
  Future<UserCredential> signInWithSocialProvider({
    required String providerName,
    required String email,
    required String fullName,
  }) async {
    final String cleanEmail = email.toLowerCase().trim();
    // Deterministic password generation for social sign-in simulation
    final String deterministicPassword = 'SocialAuth_${cleanEmail.hashCode}_BabyShop';

    try {
      // Try logging in
      return await signInWithEmailAndPassword(cleanEmail, deterministicPassword);
    } catch (e) {
      // If user-not-found or similar invalid credentials, register the user
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('user-not-found') ||
          errorStr.contains('invalid-credential') ||
          errorStr.contains('invalid email or password') ||
          errorStr.contains('no user found')) {
        return await registerWithEmailPassword(
          fullName: fullName,
          email: cleanEmail,
          password: deterministicPassword,
        );
      }
      rethrow;
    }
  }

  // ─── SAVE SOCIAL USER HELPER ───────────────────────────────────────────────
  Future<void> saveSocialUserToFirestore({
    required String uid,
    required String fullName,
    required String email,
    String? photoUrl,
    String? provider,
  }) async {
    final String cleanEmail = email.toLowerCase().trim();
    final String assignedRole = (cleanEmail == 'admin@babyshop.com' || cleanEmail == 'admin@mail.com') ? 'admin' : 'user';

    await _firestore.collection('users').doc(uid).set(
      {
        'uid': uid,
        'fullName': fullName,
        'email': cleanEmail,
        'role': assignedRole,
        'photoUrl': photoUrl,
        'provider': provider,
        'isDisabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ─── REGISTER ─────────────────────────────────────────────────────────────
  Future<UserCredential> registerWithEmailPassword({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(fullName);
        try {
          await userCredential.user!.sendEmailVerification();
        } catch (verifyError) {
          print("❌ Send email verification failed: $verifyError");
        }
        
        // Firestore save helper call safely wrapped inside a try-catch
        try {
          await saveUserToFirestore(
            uid: userCredential.user!.uid,
            fullName: fullName,
            email: email,
          );
        } catch (firestoreError) {
          print("❌ Firestore Document creation failed: $firestoreError");
          // Registration ko verify rakhne ke liye error throw nahi karenge, taake UI crash na ho
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // ─── FIRESTORE USER DOCUMENT ───────────────────────────────────────────────
  Future<void> saveUserToFirestore({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    final String cleanEmail = email.toLowerCase().trim();
    // Dynamic roles check matching the blueprint configurations
    final String assignedRole = (cleanEmail == 'admin@babyshop.com' || cleanEmail == 'admin@mail.com') ? 'admin' : 'user';

    await _firestore.collection('users').doc(uid).set(
      {
        'uid': uid,
        'fullName': fullName,
        'email': cleanEmail,
        'role': assignedRole,
        'isDisabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ─── LOGOUT ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error signing out: $e';
    }
  }

  // ─── PASSWORD CHANGE ──────────────────────────────────────────────────────
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user is signed in.';
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'requires-recent-login':
        return 'Please re-login and try again.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}