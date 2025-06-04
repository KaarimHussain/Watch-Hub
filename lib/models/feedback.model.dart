import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String feedbackType;
  final String feedbackText;
  final String userName; // Combined name field
  final String userEmail;
  final Timestamp timestamp;
  final bool isResolved;
  final List<Map<String, dynamic>>? replies;
  final String? adminReply;

  FeedbackModel({
    this.id,
    required this.feedbackType,
    required this.feedbackText,
    required this.userName,
    required this.userEmail,
    required this.timestamp,
    this.isResolved = false,
    this.replies,
    this.adminReply,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'feedbackType': feedbackType,
      'feedbackText': feedbackText,
      'userName': userName,
      'userEmail': userEmail,
      'timestamp': timestamp,
      'isResolved': isResolved,
      'replies':
          replies ??
          [
            {'text': adminReply, 'timestamp': Timestamp.now()},
          ],
    };
  }

  // Create from Firestore document
  factory FeedbackModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      feedbackType: data['feedbackType'] ?? 'Other',
      feedbackText: data['feedbackText'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userEmail: data['userEmail'] ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      isResolved: data['isResolved'] ?? false,
      replies: List<Map<String, dynamic>>.from(data['replies'] ?? []),
      adminReply: data['replies']?.last['text'] ?? '',
    );
  }
}
