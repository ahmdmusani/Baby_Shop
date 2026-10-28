import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WishlistProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _wishlistItemIds = [];

  List<String> get wishlistItemIds => _wishlistItemIds;

  WishlistProvider() {
    // Listen to authentication changes to load/clear wishlist
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadWishlistFromFirestore(user.uid);
      } else {
        _wishlistItemIds = [];
        notifyListeners();
      }
    });
  }

  bool isFavorite(String productId) {
    return _wishlistItemIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_wishlistItemIds.contains(productId)) {
      _wishlistItemIds.remove(productId);
      notifyListeners();
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'wishlist': FieldValue.arrayRemove([productId]),
        });
      } catch (e) {
        debugPrint('Error removing from wishlist: $e');
      }
    } else {
      _wishlistItemIds.add(productId);
      notifyListeners();
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'wishlist': FieldValue.arrayUnion([productId]),
        });
      } catch (e) {
        // Fallback if field doesn't exist yet, we can do set with merge
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'wishlist': [productId]
          }, SetOptions(merge: true));
        } catch (err) {
          debugPrint('Error writing to wishlist: $err');
        }
      }
    }
  }

  Future<void> _loadWishlistFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['wishlist'] != null) {
          _wishlistItemIds = List<String>.from(data['wishlist']);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
  }
}
