import 'package:flutter/material.dart';
import 'package:watch_hub/components/get_feedback_count.component.dart';
import 'package:watch_hub/components/get_lowstock_count.component.dart';
import 'package:watch_hub/components/get_total_sale.component.dart';
import 'package:watch_hub/components/get_watch_count.component.dart';

class DashboardStats extends StatefulWidget {
  const DashboardStats({super.key});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  late Future<List<dynamic>> statsFuture;

  @override
  void initState() {
    super.initState();
    statsFuture = Future.wait([
      getTotalWatches(), // index 0
      getFeedbackCount(), // index 1
      getLowStockCount(), // index 2
      getTotalSales(), // index 3
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return FutureBuilder<List<dynamic>>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        } else if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: theme.textTheme.bodyMedium,
          );
        }

        final data = snapshot.data!;
        final int totalWatches = data[0] ?? 0;
        final int feedbackCount = data[1] ?? 0;
        final int lowStockCount = data[2] ?? 0;
        final num totalSales = data[3] ?? 0;

        final stats = [
          {
            'title': 'Total Watches',
            'value': totalWatches.toString(),
            'icon': Icons.watch,
            'gradient': [Color(0xFF6A11CB), Color(0xFF2575FC)],
            'subtitle': 'In inventory',
          },
          {
            'title': 'Total Sales',
            'value': 'PKR ${totalSales.toStringAsFixed(2)}',
            'icon': Icons.attach_money,
            'gradient': [Color(0xFF11998E), Color(0xFF38EF7D)],
            'subtitle': 'This month',
          },
          {
            'title': 'Feedbacks',
            'value': feedbackCount.toString(),
            'icon': Icons.feedback,
            'gradient': [Color(0xFFFF8008), Color(0xFFFFC837)],
            'subtitle': 'From customers',
          },
          {
            'title': 'Low Stock',
            'value': lowStockCount.toString(),
            'icon': Icons.inventory,
            'gradient': [Color(0xFFFF416C), Color(0xFFFF4B2B)],
            'subtitle': 'Need attention',
          },
        ];

        // Use LayoutBuilder to make the layout responsive
        return LayoutBuilder(
          builder: (context, constraints) {
            // Determine layout based on screen width
            int crossAxisCount;
            double childAspectRatio;
            bool useCompactLayout;

            if (constraints.maxWidth < 400) {
              // Very small screens - 1 column with compact layout
              crossAxisCount = 1;
              childAspectRatio = 3.0;
              useCompactLayout = true;
            } else if (constraints.maxWidth < 600) {
              // Small screens - 1 column with standard layout
              crossAxisCount = 1;
              childAspectRatio = 3.7;
              useCompactLayout = false;
            } else if (constraints.maxWidth < 900) {
              // Medium screens - 2 columns
              crossAxisCount = 2;
              childAspectRatio = 1.5;
              useCompactLayout = false;
            } else {
              // Large screens - 2 columns
              crossAxisCount = 2;
              childAspectRatio = 1.2;
              useCompactLayout = false;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                final gradientColors = stat['gradient'] as List<Color>;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isDarkMode
                              ? [
                                gradientColors[0].withOpacity(0.8),
                                gradientColors[1].withOpacity(0.8),
                              ]
                              : gradientColors,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (stat['title'] == 'Total Watches') {
                            Navigator.pushNamed(context, '/admin_watch');
                          } else if (stat['title'] == 'Feedbacks') {
                            Navigator.pushNamed(
                              context,
                              '/admin_view_feedback',
                            );
                          } else if (stat['title'] == 'Low Stock') {
                            Navigator.pushNamed(context, '/admin_watch');
                          }
                        },
                        splashColor: Colors.white.withOpacity(0.1),
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child:
                              crossAxisCount == 1
                                  // Horizontal layout for single column mode
                                  ? _buildHorizontalStatCard(
                                    stat,
                                    theme,
                                    useCompactLayout,
                                  )
                                  // Original vertical layout for two-column mode
                                  : _buildVerticalStatCard(stat, theme),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Horizontal layout for single column mode
  Widget _buildHorizontalStatCard(
    Map<String, dynamic> stat,
    ThemeData theme,
    bool isCompact,
  ) {
    return Row(
      children: [
        // Icon section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(stat['icon'] as IconData, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        // Content section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat['title'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                stat['subtitle'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Value section - adjust based on compact layout
        if (isCompact && (stat['value'] as String).length > 10)
          // For very long values in compact mode, stack them vertically
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _formatLongValue(stat['value'] as String),
          )
        else
          // Standard display for normal values
          Text(
            stat['value'] as String,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: isCompact ? 16 : 20, // Smaller font for compact layout
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  // Helper method to format long values (like currency amounts)
  List<Widget> _formatLongValue(String value) {
    // For currency values like "PKR 10000.00"
    if (value.startsWith('PKR ')) {
      return [
        Text(
          'PKR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        Text(
          value.substring(4), // Remove "PKR " prefix
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ];
    }

    // For other long values
    return [
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ];
  }

  // Vertical layout for multi-column mode
  Widget _buildVerticalStatCard(Map<String, dynamic> stat, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat['title'] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    stat['subtitle'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                stat['icon'] as IconData,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Handle long values by adjusting font size
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            stat['value'] as String,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
