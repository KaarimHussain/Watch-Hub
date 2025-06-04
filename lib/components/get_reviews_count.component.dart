import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<int?> getReviewsCount(String userId) async {
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: userId)
            .count()
            .get();

    debugPrint('Reviews count: ${snapshot.count}');
    return snapshot.count;
  } catch (e) {
    debugPrint('Error fetching reviews count: $e');
    return 0;
  }
}
