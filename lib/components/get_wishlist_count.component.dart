import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<int?> getWishlistCount(String userId) async {
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('wishlist')
            .where('userId', isEqualTo: userId)
            .count()
            .get();

    debugPrint('Wishlist count: ${snapshot.count}');
    return snapshot.count;
  } catch (e) {
    debugPrint('Error fetching wishlist count: $e');
    return 0;
  }
}
