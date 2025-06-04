// get_total_orders.component.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<int?> getTotalOrders() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance.collection('orders').count().get();
    return snapshot.count;
  } catch (e) {
    print('Error fetching orders count: $e');
    return 0;
  }
}
