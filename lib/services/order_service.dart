import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new order
  Future<String> createOrder(Map<String, dynamic> orderData) async {
    try {
      // Add the order to Firestore
      final docRef = await _firestore.collection('orders').add(orderData);

      // Update the order with its ID
      await docRef.update({'orderId': docRef.id});

      // Return the order ID
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get orders for a specific user
  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .orderBy('orderDate', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => {'orderId': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  // Get a specific order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();

      if (doc.exists) {
        return {'orderId': doc.id, ...doc.data()!};
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'orderStatus': status,
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<String?> getOrderStatus(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();

      if (doc.exists) {
        return doc.data()!['orderStatus'];
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'paymentStatus': status,
      });
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Get Payment Status
  Future<String?> getPaymentStatus(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();

      if (doc.exists) {
        return doc.data()!['paymentStatus'];
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get payment status: $e');
    }
  }
}
