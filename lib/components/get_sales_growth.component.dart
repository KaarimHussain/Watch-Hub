// get_sales_growth.component.dart
import 'package:watch_hub/components/get_monthly_sale.component.dart';
import 'package:watch_hub/components/get_previous_month_sale.component.dart';

Future<double> getSalesGrowth() async {
  try {
    final currentMonth = await getMonthlySales() ?? 0.0;
    final previousMonth = await getPreviousMonthSales() ?? 0.0;

    if (previousMonth == 0) return 0.0;

    final growth = ((currentMonth - previousMonth) / previousMonth) * 100;
    return growth;
  } catch (e) {
    print('Error calculating sales growth: $e');
    return 0.0;
  }
}
