import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<int?> getLowStockCount() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('watches')
            .where('stockCount', isLessThan: 10)
            .count()
            .get();

    debugPrint('Low stock count: ${snapshot.count}');
    return snapshot.count;
  } catch (e) {
    debugPrint('Error fetching low stock count: $e');
    return 0;
  }
}
