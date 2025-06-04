// get_delivered_orders.component.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<int?> getDeliveredOrders() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where('orderStatus', isEqualTo: 'Delivered')
            .count()
            .get();
    return snapshot.count;
  } catch (e) {
    print('Error fetching delivered orders count: $e');
    return 0;
  }
}
