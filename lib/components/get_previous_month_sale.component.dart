// get_previous_month_sales.component.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<double?> getPreviousMonthSales() async {
  try {
    final now = DateTime.now();
    final startOfPrevMonth = DateTime(now.year, now.month - 1, 1);
    final endOfPrevMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where('orderStatus', isEqualTo: 'Delivered')
            .where(
              'orderDate',
              isGreaterThanOrEqualTo: startOfPrevMonth.toIso8601String(),
            )
            .where(
              'orderDate',
              isLessThanOrEqualTo: endOfPrevMonth.toIso8601String(),
            )
            .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      total += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  } catch (e) {
    print('Error fetching previous month sales: $e');
    return 0.0;
  }
}
