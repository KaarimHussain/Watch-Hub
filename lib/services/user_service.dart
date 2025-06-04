import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return doc.data();
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get user details: $e');
    }
  }

  // Update user details
  Future<void> updateUserDetails(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user details: $e');
    }
  }

  // Save shipping address
  Future<void> saveShippingAddress(
    String userId,
    Map<String, dynamic> address,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': address['name'],
        'phone': address['phone'],
        'addressLine1': address['addressLine1'],
        'addressLine2': address['addressLine2'],
        'city': address['city'],
        'state': address['state'],
        'zipCode': address['zipCode'],
      });
    } catch (e) {
      throw Exception('Failed to save shipping address: $e');
    }
  }
}
