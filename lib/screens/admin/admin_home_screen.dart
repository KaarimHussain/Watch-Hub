import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/screens/admin/admin_drawer.dart';
import 'package:watch_hub/screens/admin/dashboard_stats.dart';
import 'package:watch_hub/components/get_total_orders.component.dart';
import 'package:watch_hub/components/get_total_collection.component.dart';
import 'package:watch_hub/components/get_pending_orders.component.dart';
import 'package:watch_hub/components/get_orders_delivered.component.dart';
import 'package:watch_hub/components/get_sales_growth.component.dart';
import 'package:watch_hub/components/get_weekly_orders.component.dart';
import 'dart:math' as math;

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Theme colors from your app
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color darkGray = Color(0xFF343A40);
  static const Color mediumGray = Color(0xFF6C757D);
  static const Color lightGray = Color(0xFFCED4DA);
  static const Color accentGray = Color(0xFFADB5BD);

  // Additional dashboard data
  Map<String, dynamic> additionalData = {
    'totalOrders': 0,
    'totalCollections': 0,
    'pendingOrders': 0,
    'deliveredOrders': 0,
    'salesGrowth': 0.0,
    'weeklyOrders': <Map<String, dynamic>>[],
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadAdditionalData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAdditionalData() async {
    try {
      final results = await Future.wait([
        getTotalOrders(),
        getTotalCollections(),
        getPendingOrders(),
        getDeliveredOrders(),
        getSalesGrowth(),
        getWeeklyOrders(),
      ]);

      setState(() {
        additionalData['totalOrders'] = results[0] ?? 0;
        additionalData['totalCollections'] = results[1] ?? 0;
        additionalData['pendingOrders'] = results[2] ?? 0;
        additionalData['deliveredOrders'] = results[3] ?? 0;
        additionalData['salesGrowth'] = results[4] ?? 0.0;
        additionalData['weeklyOrders'] = results[5] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading additional data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: darkGray),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkGray,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadAdditionalData();
            },
          ),
        ],
      ),
      drawer: const AdminDrawer(selectedIndex: 0),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadAdditionalData,
          color: darkGray,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),

                  // Your existing DashboardStats component
                  const DashboardStats(),

                  const SizedBox(height: 24),
                  _buildAdditionalKPIs(),
                  const SizedBox(height: 24),
                  _buildOrdersChart(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildRecentActivities(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour >= 17) {
      greeting = 'Good evening';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkGray, darkGray.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkGray.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, Admin!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your watch store overview for today',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          if (!_isLoading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  additionalData['salesGrowth'] >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color:
                      additionalData['salesGrowth'] >= 0
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${additionalData['salesGrowth'].toStringAsFixed(1)}% ${additionalData['salesGrowth'] >= 0 ? 'growth' : 'decline'} this month',
                  style: TextStyle(
                    color:
                        additionalData['salesGrowth'] >= 0
                            ? Colors.green.shade300
                            : Colors.red.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalKPIs() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: darkGray));
    }

    final kpis = [
      {
        'title': 'Total Orders',
        'value': '${additionalData['totalOrders']}',
        'icon': Icons.shopping_cart,
        'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
        'subtitle': 'All time',
      },
      {
        'title': 'Collections',
        'value': '${additionalData['totalCollections']}',
        'icon': Icons.collections,
        'gradient': [const Color(0xFFf093fb), const Color(0xFFF441a5)],
        'subtitle': 'Created',
      },
      {
        'title': 'Pending Orders',
        'value': '${additionalData['pendingOrders']}',
        'icon': Icons.pending_actions,
        'gradient': [const Color(0xFFffecd2), const Color(0xFFfcb69f)],
        'subtitle': 'Need attention',
      },
      {
        'title': 'Delivered',
        'value': '${additionalData['deliveredOrders']}',
        'icon': Icons.check_circle,
        'gradient': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
        'subtitle': 'Completed',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleColumn = constraints.maxWidth < 600;
        final crossAxisCount = isSingleColumn ? 1 : 2;
        final childAspectRatio = isSingleColumn ? 3.7 : 1.2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, index) {
            final kpi = kpis[index];
            final gradientColors = kpi['gradient'] as List<Color>;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (kpi['title'] == 'Total Orders' ||
                          kpi['title'] == 'Pending Orders' ||
                          kpi['title'] == 'Delivered') {
                        Navigator.pushNamed(context, '/admin_orders');
                      } else if (kpi['title'] == 'Collections') {
                        Navigator.pushNamed(context, '/admin_collection');
                      }
                    },
                    splashColor: Colors.white.withOpacity(0.1),
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child:
                          isSingleColumn
                              ? Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      kpi['icon'] as IconData,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          kpi['title'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          kpi['subtitle'] as String,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    kpi['value'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              kpi['title'] as String,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              kpi['subtitle'] as String,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          kpi['icon'] as IconData,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    kpi['value'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersChart() {
    if (_isLoading) {
      return Container(
        height: 200,
        child: const Center(child: CircularProgressIndicator(color: darkGray)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Orders Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Last 7 days',
                  style: TextStyle(
                    fontSize: 12,
                    color: mediumGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 200, child: _buildOrdersBarChart()),
        ],
      ),
    );
  }

  Widget _buildOrdersBarChart() {
    final ordersData =
        additionalData['weeklyOrders'] as List<Map<String, dynamic>>;
    if (ordersData.isEmpty) {
      return const Center(
        child: Text(
          'No orders data available',
          style: TextStyle(color: mediumGray),
        ),
      );
    }

    final maxOrders =
        ordersData.isNotEmpty
            ? ordersData.map((e) => e['orders'] as int).reduce(math.max)
            : 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          ordersData.map((data) {
            final orders = data['orders'] as int;
            final date = data['date'] as String;
            final height = maxOrders > 0 ? (orders / maxOrders) * 150 : 0.0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$orders',
                  style: const TextStyle(fontSize: 10, color: mediumGray),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 30,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [darkGray, darkGray.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: const TextStyle(fontSize: 10, color: mediumGray),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'Manage Products',
        'subtitle': 'Add, edit, or remove watches',
        'icon': Icons.watch,
        'color': Colors.blue,
        'route': '/admin_watch',
      },
      {
        'title': 'Collections',
        'subtitle': 'Organize watch collections',
        'icon': Icons.collections,
        'color': Colors.purple,
        'route': '/admin_collection',
      },
      {
        'title': 'Orders',
        'subtitle': 'View and manage orders',
        'icon': Icons.shopping_cart,
        'color': Colors.green,
        'route': '/admin_orders',
      },
      {
        'title': 'Users',
        'subtitle': 'Manage user accounts',
        'icon': Icons.people,
        'color': Colors.orange,
        'route': '/admin_user',
      },
      {
        'title': 'Add Product',
        'subtitle': 'Add new watch to inventory',
        'icon': Icons.add_circle,
        'color': Colors.teal,
        'route': '/admin_add_watch',
      },
      {
        'title': 'Feedback',
        'subtitle': 'View customer feedback',
        'icon': Icons.feedback,
        'color': Colors.amber,
        'route': '/admin_view_feedback',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkGray,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Determine grid layout based on screen width
            int crossAxisCount;
            double childAspectRatio;

            if (constraints.maxWidth < 400) {
              // Very small screens - 1 column
              crossAxisCount = 1;
              childAspectRatio = 3.0;
            } else if (constraints.maxWidth < 600) {
              // Small screens - 2 columns with adjusted aspect ratio
              crossAxisCount = 2;
              childAspectRatio = 1.5;
            } else if (constraints.maxWidth < 900) {
              // Medium screens - 2 columns with more square aspect ratio
              crossAxisCount = 2;
              childAspectRatio = 1.3;
            } else {
              // Large screens - 3 columns
              crossAxisCount = 3;
              childAspectRatio = 1.2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildQuickActionCard(
                  title: action['title'] as String,
                  subtitle: action['subtitle'] as String,
                  icon: action['icon'] as IconData,
                  color: action['color'] as Color,
                  onTap: () {
                    Navigator.pushNamed(context, action['route'] as String);
                  },
                  isHorizontal:
                      crossAxisCount ==
                      1, // Use horizontal layout for single column
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Replace the _buildQuickActionCard method with this improved version
  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isHorizontal = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              isHorizontal
                  // Horizontal layout for single column view
                  ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: mediumGray,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: mediumGray,
                      ),
                    ],
                  )
                  // Original vertical layout for multi-column view
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: mediumGray),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin_recent_activities');
                  // Navigate to full activity log
                },
                child: const Text(
                  'View All',
                  style: TextStyle(color: darkGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('recentActivity')
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: darkGray),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: mediumGray),
                    ),
                  ),
                );
              }

              final activities = snapshot.data!.docs;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder:
                    (context, index) =>
                        const Divider(height: 32, color: lightGray),
                itemBuilder: (context, index) {
                  final data = activities[index].data() as Map<String, dynamic>;

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: darkGray.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          getIconData(data['type'] ?? ''),
                          color: darkGray,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: darkGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['description'] ?? '',
                              style: const TextStyle(
                                color: mediumGray,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        data['time'] ?? '',
                        style: const TextStyle(color: accentGray, fontSize: 12),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  IconData getIconData(String iconName) {
    String icon = iconName.toLowerCase();
    switch (icon) {
      case 'add_watch':
        return Icons.watch;
      case 'update_watch':
        return Icons.edit;
      case 'delete_watch':
        return Icons.delete;
      case 'feedback':
        return Icons.feedback;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'user':
        return Icons.person;
      case 'order':
        return Icons.shopping_cart;
      case 'collection':
        return Icons.collections;
      default:
        return Icons.notifications;
    }
  }
}
