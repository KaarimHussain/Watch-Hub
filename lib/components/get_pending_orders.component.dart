// get_pending_orders.component.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<int?> getPendingOrders() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where('orderStatus', isEqualTo: 'Processing')
            .count()
            .get();
    return snapshot.count;
  } catch (e) {
    print('Error fetching pending orders count: $e');
    return 0;
  }
}
