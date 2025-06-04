import 'package:flutter/material.dart';
import 'package:watch_hub/components/logo.component.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/screens/admin/admin_home_screen.dart';
import 'package:watch_hub/screens/admin/watch_screen.dart';
import 'package:watch_hub/screens/base/login_screen.dart';
import 'package:watch_hub/services/auth_service.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;

  const AdminDrawer({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediumGray = theme.colorScheme.secondary;

    return Drawer(
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Enhanced drawer header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with subtle shadow
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: logoComponent(),
                ),
                const SizedBox(height: 16),
                // App name with enhanced typography
                Text(
                  'WATCH HUB',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Cal_Sans',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtitle with subtle styling
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Admin Dashboard',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navigation section with improved spacing
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'NAVIGATION',
                style: TextStyle(
                  color: mediumGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // Enhanced navigation items
          _buildDrawerItem(
            context,
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            isSelected: selectedIndex == 0,
            onTap: () {
              if (selectedIndex != 0) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AdminHomeScreen(),
                  ),
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
                  MaterialPageRoute(builder: (context) => const WatchScreen()),
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
                Navigator.pushReplacementNamed(context, '/admin_view_feedback');
              } else {
                Navigator.pop(context);
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person_outline,
            title: 'Users',
            isSelected: selectedIndex == 3,
            onTap: () {
              if (selectedIndex != 3) {
                Navigator.pushReplacementNamed(context, '/admin_user');
              } else {
                Navigator.pop(context);
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.collections,
            title: 'Collection',
            isSelected: selectedIndex == 4,
            onTap: () {
              if (selectedIndex != 4) {
                Navigator.pushReplacementNamed(context, '/admin_collection');
              } else {
                Navigator.pop(context);
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.shopping_cart_outlined,
            title: 'Orders',
            isSelected: selectedIndex == 5,
            onTap: () {
              if (selectedIndex != 5) {
                Navigator.pushReplacementNamed(context, '/admin_orders');
              } else {
                Navigator.pop(context);
              }
            },
          ),

          const Spacer(),

          // Enhanced divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: theme.colorScheme.primary.withOpacity(0.1),
              thickness: 1,
            ),
          ),

          // Enhanced logout section
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: theme.colorScheme.error,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontFamily: 'Cal_Sans',
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Are you sure you want to logout from your admin account?',
                          style: theme.textTheme.bodyMedium,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              AuthService().logout(context);
                              showSnackBar(
                                context,
                                "Logged out successfully",
                                type: SnackBarType.success,
                              );
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: theme.colorScheme.error.withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
