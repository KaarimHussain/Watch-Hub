// get_total_collections.component.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<int?> getTotalCollections() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('perfect_collection')
        .count()
        .get();
    return snapshot.count;
  } catch (e) {
    return 0;
  }
}