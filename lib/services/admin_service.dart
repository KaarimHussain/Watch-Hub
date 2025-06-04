import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteUser(String docId) async {
    try {
      await _firestore.collection('users').doc(docId).delete();
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  Future<void> deleteUserFromReviewCollection(String docId) async {
    try {
      await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: docId)
          .get()
          .then((querySnapshot) {
            for (var doc in querySnapshot.docs) {
              doc.reference.delete();
            }
          });
    } catch (e) {
      print("Error deleting user from review collection: $e");
    }
  }

  Future<void> deleteUserFromWishlist(String docId) async {
    try {
      await _firestore
          .collection('wishlist')
          .where('userId', isEqualTo: docId)
          .get()
          .then((querySnapshot) {
            for (var doc in querySnapshot.docs) {
              doc.reference.delete();
            }
          });
    } catch (e) {
      print("Error deleting user from wishlist collection: $e");
    }
  }

  Future<void> deleteUserFeedback(String docId) async {
    try {
      await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: docId)
          .get()
          .then((querySnapshot) {
            for (var doc in querySnapshot.docs) {
              doc.reference.delete();
            }
          });
    } catch (e) {
      print("Error deleting user from feedback collection: $e");
    }
  }
}
