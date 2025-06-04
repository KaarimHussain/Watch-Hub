import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watch_hub/models/feedback.model.dart';

class FeedbackService {
  final CollectionReference _feedbackCollection = FirebaseFirestore.instance
      .collection('feedback');

  // Add feedback
  Future<void> addFeedback(FeedbackModel feedback) async {
    await _feedbackCollection.add(feedback.toMap());
  }

  // Get all feedback
  Stream<QuerySnapshot> getFeedback() {
    return _feedbackCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Update feedback status
  Future<void> updateFeedbackStatus(String feedbackId, bool isResolved) async {
    await _feedbackCollection.doc(feedbackId).update({
      'isResolved': isResolved,
    });
  }

  // Add reply to feedback
  Future<void> addReply(
    String feedbackId,
    String replyText,
    String adminName,
  ) async {
    await _feedbackCollection.doc(feedbackId).update({
      'replies': FieldValue.arrayUnion([
        {
          'text': replyText,
          'timestamp': Timestamp.now(),
          'adminName': adminName,
        },
      ]),
    });
  }

  Future<void> sendReply(
    String feedbackId,
    String replyText,
    String adminName,
  ) async {
    await _feedbackCollection.doc(feedbackId).update({
      'replies': FieldValue.arrayUnion([
        {
          'text': replyText,
          'timestamp': Timestamp.now(),
          'adminName': adminName,
        },
      ]),
    });
  }

  Future<List<FeedbackModel>> getFeedbackList(String email) async {
    final snapshot =
        await _feedbackCollection.where('userEmail', isEqualTo: email).get();
    return snapshot.docs.map((doc) => FeedbackModel.fromDocument(doc)).toList();
  }
}
