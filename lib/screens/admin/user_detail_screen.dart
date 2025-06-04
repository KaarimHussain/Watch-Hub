import 'package:flutter/material.dart';
import 'package:watch_hub/components/format_date.component.dart';
import 'package:watch_hub/models/signup.model.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key, required this.user});

  final SignupModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkGray = theme.colorScheme.primary;
    final mediumGray = theme.colorScheme.secondary;

    // Generate avatar color based on user name
    final String name = user.name;
    final int colorValue = name.hashCode % Colors.primaries.length;
    final Color avatarColor = Colors.primaries[colorValue];

    // Format the date
    final formattedDate = formatTimestampToTimeAgo(user.createdAt);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Details',
          style: TextStyle(fontFamily: 'Cal_Sans'),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Hero(
                    tag: 'user-avatar-${user.email}',
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: avatarColor.withOpacity(0.2),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: avatarColor,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User name
                  Text(
                    user.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cal_Sans',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // User role badge
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: darkGray.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Customer',
                      style: TextStyle(
                        color: darkGray,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // Account creation date
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: mediumGray,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Member since $formattedDate',
                        style: TextStyle(color: mediumGray, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact information section
            _buildSection(
              context,
              title: 'Contact Information',
              icon: Icons.contact_mail_outlined,
              children: [
                _buildInfoItem(
                  context,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user.email,
                ),
                _buildInfoItem(
                  context,
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: user.phone ?? 'Not provided',
                  isPlaceholder: user.phone == null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Address section
            _buildSection(
              context,
              title: 'Address',
              icon: Icons.location_on_outlined,
              children: [
                _buildInfoItem(
                  context,
                  icon: Icons.home_outlined,
                  label: 'Home Address',
                  value: user.address ?? 'Not provided',
                  isPlaceholder: user.address == null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Account activity section
            _buildSection(
              context,
              title: 'Account Activity',
              icon: Icons.history_outlined,
              children: [
                _buildInfoItem(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  label: 'Orders',
                  value: '0 orders',
                ),
                _buildInfoItem(
                  context,
                  icon: Icons.favorite_border_outlined,
                  label: 'Wishlist Items',
                  value: '0 items',
                ),
                _buildInfoItem(
                  context,
                  icon: Icons.star_border_outlined,
                  label: 'Reviews',
                  value: '0 reviews',
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper method to build information sections
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),

          // Section content
          ...children,
        ],
      ),
    );
  }

  // Helper method to build information items
  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isPlaceholder = false,
  }) {
    final theme = Theme.of(context);
    final mediumGray = theme.colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: mediumGray, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: mediumGray, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color:
                        isPlaceholder
                            ? mediumGray.withOpacity(0.7)
                            : theme.colorScheme.primary,
                    fontSize: 16,
                    fontWeight:
                        isPlaceholder ? FontWeight.normal : FontWeight.w500,
                    fontStyle:
                        isPlaceholder ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
