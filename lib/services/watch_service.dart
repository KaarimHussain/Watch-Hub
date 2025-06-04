import 'package:cloud_firestore/cloud_firestore.dart';

class WatchService {
  final _watches = FirebaseFirestore.instance.collection('watches');

  List<QueryDocumentSnapshot>? _cachedWatches;
  DateTime? _lastFetchTime;
  final Duration _cacheDuration = const Duration(minutes: 5);

  // Get All Watches with caching
  Future<List<QueryDocumentSnapshot>> getAllWatches({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    if (!forceRefresh &&
        _cachedWatches != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheDuration) {
      // Return cached data
      return _cachedWatches!;
    }

    // Fetch from Firestore
    final querySnapshot = await _watches.get();
    _cachedWatches = querySnapshot.docs;
    _lastFetchTime = now;
    return _cachedWatches!;
  }

  Future<Map<String, dynamic>?> getWatchById(String watchId) async {
    try {
      final docSnapshot = await _watches.doc(watchId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Add this method to update watch stock
  Future<void> updateWatchStock(String watchId, int newStockCount) async {
    try {
      await _watches.doc(watchId).update({'stockCount': newStockCount});
    } catch (e) {
      throw Exception('Failed to update watch stock: $e');
    }
  }

  // Optional: Clear the cache manually
  void clearCache() {
    _cachedWatches = null;
    _lastFetchTime = null;
  }
}
