import 'package:flutter/material.dart';
import 'package:watch_hub/components/logo.component.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Information'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Name
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: logoComponent(),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'WatchHub',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Precious Timepieces',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // About Section
            _buildInfoSection(
              context,
              'About WatchHub',
              'WatchHub is your premier destination for authentic luxury and premium watches. We curate the finest timepieces from renowned brands worldwide, ensuring every watch meets our strict quality standards.\n\nOur mission is to make luxury accessible while maintaining the highest standards of authenticity and customer service.',
              Icons.info_outline,
            ),

            const SizedBox(height: 20),

            // Features Section
            _buildInfoSection(
              context,
              'Key Features',
              '• Authentic watches from authorized dealers\n• 30-day return policy\n• Manufacturer warranty included\n• Expert customer support\n• Secure payment processing\n• Global shipping available\n• Virtual try-on technology\n• Watch insurance options',
              Icons.star_outline,
            ),

            const SizedBox(height: 20),

            // Security Section
            _buildInfoSection(
              context,
              'Security & Trust',
              'Your security is our priority. We use industry-standard encryption to protect your personal and payment information. All transactions are processed through secure payment gateways.\n\nEvery watch comes with a certificate of authenticity and is thoroughly inspected by our expert team before shipping.',
              Icons.security,
            ),

            const SizedBox(height: 20),

            // Contact Information
            _buildInfoSection(
              context,
              'Contact Information',
              'Customer Support: 24/7 Live Chat\nEmail: support@watchhub.com\nPhone: +1 (555) 123-WATCH\n\nBusiness Hours:\nMonday - Friday: 9:00 AM - 8:00 PM\nSaturday - Sunday: 10:00 AM - 6:00 PM\n\nHeadquarters:\n123 Luxury Avenue\nTimepiece District, NY 10001',
              Icons.contact_support,
            ),

            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Terms of Service',
                    Icons.description,
                    () {
                      // Navigate to terms
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Privacy Policy',
                    Icons.privacy_tip,
                    () {
                      // Navigate to privacy policy
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Version Info
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Version 2.1.0',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '© 2024 WatchHub. All rights reserved.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    final _ = Theme.of(context);

    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
