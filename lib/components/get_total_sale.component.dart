import 'package:cloud_firestore/cloud_firestore.dart';

Future<num> getTotalSales() async {
  try {
    // Query only delivered orders
    final snapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where('orderStatus', isEqualTo: 'Delivered')
            .get();

    if (snapshot.docs.isEmpty) {
      return 0;
    }

    // Sum all grandTotal values
    num total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('grandTotal')) {
        final value = data['grandTotal'];
        if (value is num) {
          total += value;
        } else if (value is String) {
          // In case grandTotal is stored as a string, try parsing
          final parsedValue = num.tryParse(value);
          if (parsedValue != null) {
            total += parsedValue;
          }
        }
      }
    }

    return total;
  } catch (e) {
    print('Error fetching total sales: $e');
    return 0;
  }
}
