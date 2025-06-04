// get_monthly_sales.component.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<double?> getMonthlySales() async {
  try {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where('orderStatus', isEqualTo: 'Delivered')
            .where(
              'orderDate',
              isGreaterThanOrEqualTo: startOfMonth.toIso8601String(),
            )
            .where(
              'orderDate',
              isLessThanOrEqualTo: endOfMonth.toIso8601String(),
            )
            .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      total += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  } catch (e) {
    print('Error fetching monthly sales: $e');
    return 0.0;
  }
}
