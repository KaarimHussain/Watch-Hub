import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<int?> getFeedbackCount() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance.collection('feedback').count().get();

    debugPrint('Feedback count: ${snapshot.count}');
    return snapshot.count;
  } catch (e) {
    debugPrint('Error fetching feedback count: $e');
    return 0;
  }
}
