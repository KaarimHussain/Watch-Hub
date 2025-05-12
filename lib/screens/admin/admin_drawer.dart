import 'package:flutter/material.dart';
import 'package:watch_hub/components/logo.component.dart';
import 'package:watch_hub/screens/admin/admin_home_screen.dart';
import 'package:watch_hub/screens/admin/watch_screen.dart';
import 'package:watch_hub/screens/base/login_screen.dart';
import 'package:watch_hub/services/auth_service.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;

  const AdminDrawer({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                logoComponent(),
                const SizedBox(height: 12),
                const Text(
                  'WATCH HUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Cal_Sans',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your watch store',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            isSelected: selectedIndex == 0,
            onTap: () {
              if (selectedIndex != 0) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => AdminHomeScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.watch_outlined,
            title: 'Watches',
            isSelected: selectedIndex == 1,
            onTap: () {
              if (selectedIndex != 1) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => WatchScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            isSelected: selectedIndex == 2,
            onTap: () {
              if (selectedIndex != 2) {
                // Navigator.of(context).pushReplacement(
                //   MaterialPageRoute(
                //     builder: (context) => const FeedbackScreen(),
                //   ),
                // );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Spacer(),
          const Divider(color: Colors.grey),
          _buildDrawerItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            isSelected: false,
            onTap: () {},
          ),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            isSelected: false,
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor: const Color(0xFF121212),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cal_Sans',
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(
                          color: Color.fromARGB(255, 216, 216, 216),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            AuthService().logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
