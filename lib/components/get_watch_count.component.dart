import 'package:cloud_firestore/cloud_firestore.dart';

Future<int?> getTotalWatches() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance.collection('watches').count().get();
    return snapshot.count;
  } catch (e) {
    print('Error fetching watch count: $e');
    return 0;
  }
}
