import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/models/recent_activity.model.dart';

class RecentActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addRecentActivity(RecentActivity activity) async {
    try {
      await _firestore.collection('recentActivity').add(activity.toJson());
    } catch (e) {
      debugPrint('Failed to add recent activity: $e');
    }
  }
}
