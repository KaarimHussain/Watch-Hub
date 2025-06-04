// get_weekly_orders.component.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> getWeeklyOrders() async {
  try {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where(
              'orderDate',
              isGreaterThanOrEqualTo: weekAgo.toIso8601String(),
            )
            .orderBy('orderDate', descending: false)
            .get();

    // Group orders by day
    Map<String, int> dailyOrders = {};
    for (int i = 0; i < 7; i++) {
      final date = weekAgo.add(Duration(days: i));
      final dateKey = '${date.day}/${date.month}';
      dailyOrders[dateKey] = 0;
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final orderDate = DateTime.parse(data['orderDate']);
      final dateKey = '${orderDate.day}/${orderDate.month}';
      if (dailyOrders.containsKey(dateKey)) {
        dailyOrders[dateKey] = dailyOrders[dateKey]! + 1;
      }
    }

    return dailyOrders.entries
        .map((entry) => {'date': entry.key, 'orders': entry.value})
        .toList();
  } catch (e) {
    print('Error fetching weekly orders: $e');
    return [];
  }
}
