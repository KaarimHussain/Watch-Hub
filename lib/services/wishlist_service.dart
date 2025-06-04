import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:watch_hub/models/wishlist.model.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot>? _cachedWishlist; // Cached wishlist
  String? _cachedUserId; // Track for which user this cache belongs

  Future<bool> addWishlist(WishList wishlistData) async {
    try {
      final exists = await getWishlist(wishlistData.watchId);
      if (exists) return false;

      await _firestore.collection('wishlist').add(wishlistData.toMap());

      // Invalidate cache since new item was added
      _cachedWishlist = null;

      return true;
    } catch (e) {
      debugPrint('Error adding wishlist: $e');
      return false;
    }
  }

  Future<bool> removeWishlist(WishList wishlistData) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('wishlist')
              .where('userId', isEqualTo: wishlistData.userId)
              .where('watchId', isEqualTo: wishlistData.watchId)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();

        // Invalidate cache since an item was removed
        _cachedWishlist = null;

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing wishlist: $e');
      return false;
    }
  }

  Future<bool> getWishlist(String watchId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Use cache if available and valid
    if (_cachedWishlist != null && _cachedUserId == userId) {
      return _cachedWishlist!.any((doc) => doc['watchId'] == watchId);
    }

    // Otherwise fetch from Firestore
    final wishlistSnapshot =
        await _firestore
            .collection('wishlist')
            .where('userId', isEqualTo: userId)
            .get();

    _cachedWishlist = wishlistSnapshot.docs;
    _cachedUserId = userId;

    return _cachedWishlist!.any((doc) => doc['watchId'] == watchId);
  }

  Future<List<DocumentSnapshot>> getWishlistByUser(String userId) async {
    // Return from cache if valid
    if (_cachedWishlist != null && _cachedUserId == userId) {
      return _cachedWishlist!;
    }

    final snapshot =
        await _firestore
            .collection('wishlist')
            .where('userId', isEqualTo: userId)
            .get();

    _cachedWishlist = snapshot.docs;
    _cachedUserId = userId;

    return _cachedWishlist!;
  }
}
