import 'package:flutter/material.dart';
import 'package:watch_hub/screens/admin/admin_drawer.dart';
import 'package:watch_hub/screens/admin/dashboard_stats.dart';
// import 'package:watch_hub/services/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Auth Service
  // final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
      ),
      drawer: AdminDrawer(selectedIndex: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back, Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s what\'s happening with your watch store today.',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 24),
              const DashboardStats(),
              const SizedBox(height: 24),
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentActivitiesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesList() {
    final activities = [
      {
        'title': 'New watch added',
        'description': 'Luxury Watch XYZ was added to inventory',
        'time': '2 hours ago',
        'icon': Icons.watch,
      },
      {
        'title': 'New feedback received',
        'description': 'Customer John D. left a 5-star review',
        'time': '5 hours ago',
        'icon': Icons.feedback,
      },
      {
        'title': 'Watch updated',
        'description': 'Sport Watch ABC price was updated',
        'time': '1 day ago',
        'icon': Icons.edit,
      },
      {
        'title': 'Watch removed',
        'description': 'Vintage Watch DEF was removed from inventory',
        'time': '2 days ago',
        'icon': Icons.delete,
      },
    ];

    return Card(
      color: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder:
            (context, index) => const Divider(height: 1, color: Colors.grey),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(activity['icon'] as IconData, color: Colors.white),
            ),
            title: Text(
              activity['title'] as String,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              activity['description'] as String,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: Text(
              activity['time'] as String,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
