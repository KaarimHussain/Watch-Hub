import 'package:flutter/material.dart';

class DashboardStats extends StatefulWidget {
  const DashboardStats({super.key});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'title': 'Total Watches',
        'value': '124',
        'change': '+12%',
        'isPositive': true,
        'icon': Icons.watch,
      },
      {
        'title': 'Total Sales',
        'value': '\$24,300',
        'change': '+18%',
        'isPositive': true,
        'icon': Icons.attach_money,
      },
      {
        'title': 'New Feedback',
        'value': '32',
        'change': '+24%',
        'isPositive': true,
        'icon': Icons.feedback,
      },
      {
        'title': 'Low Stock',
        'value': '5',
        'change': '-2',
        'isPositive': false,
        'icon': Icons.inventory,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          color: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stat['title'] as String,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        stat['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      (stat['isPositive'] as bool)
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color:
                          (stat['isPositive'] as bool)
                              ? Colors.green
                              : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stat['change'] as String,
                      style: TextStyle(
                        color:
                            (stat['isPositive'] as bool)
                                ? Colors.green
                                : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ' from last month',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
