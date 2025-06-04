import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<double?> getAverageRatingCount(String watchId) async {
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('reviews')
            .where('watchId', isEqualTo: watchId)
            .get();

    if (snapshot.docs.isNotEmpty) {
      double total = 0.0;

      for (var doc in snapshot.docs) {
        final ratingValue = doc['rating'];
        total += (ratingValue is num) ? ratingValue.toDouble() : 0.0;
      }

      return total / snapshot.docs.length;
    }

    return 0.0;
  } catch (e) {
    debugPrint('Error fetching average rating count: $e');
    return 0.0;
  }
}
