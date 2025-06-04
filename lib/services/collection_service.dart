import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionService {
  Future<List<Map<String, dynamic>>> getAllCollections() async {
    // Assuming you're using Firestore
    final collection =
        await FirebaseFirestore.instance.collection('perfect_collection').get();
    return collection.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getCollectionsForCarousel() async {
    // Assuming you're using Firestore
    final collection =
        await FirebaseFirestore.instance
            .collection('perfect_collection')
            .limit(5)
            .get();
    return collection.docs.map((doc) => doc.data()).toList();
  }
}
