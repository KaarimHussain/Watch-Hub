// ignore_for_file: unused_field

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watch_hub/components/get_reviews_count.component.dart';
import 'package:watch_hub/components/get_wishlist_count.component.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/screens/base/login_screen.dart';
import 'package:watch_hub/screens/user/order_screen.dart';
import 'package:watch_hub/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // Separate loading states for different sections
  bool _isProfileLoading = true;
  bool _isStatsLoading = true;

  // Error states
  bool _hasProfileError = false;
  bool _hasStatsError = false;
  String _profileErrorMessage = '';
  String _statsErrorMessage = '';

  String? _profileImageUrl;
  Map<String, dynamic>? _userData;
  int _orderCount = 0;
  int _wishlistCount = 0;
  int _reviewCount = 0;

  // TextControllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(); // Read-only
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load data independently
    _loadProfileData();
    _loadStatsData();
  }

  // Load basic profile data
  Future<void> _loadProfileData() async {
    setState(() {
      _isProfileLoading = true;
      _hasProfileError = false;
      _profileErrorMessage = '';
    });

    final uid = auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isProfileLoading = false;
        _hasProfileError = true;
        _profileErrorMessage = 'User not logged in';
      });
      return;
    }

    try {
      // Fetch user profile
      final doc = await firestore.collection('users').doc(uid).get();
      final data = doc.data();

      if (data != null) {
        setState(() {
          _userData = data;
          _profileImageUrl = _userData?['profileImage'];
          _isProfileLoading = false;
        });
      } else {
        setState(() {
          _isProfileLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      setState(() {
        _isProfileLoading = false;
        _hasProfileError = true;
        _profileErrorMessage = 'Failed to load profile: $e';
      });
    }
  }

  // Load stats data separately
  Future<void> _loadStatsData() async {
    setState(() {
      _isStatsLoading = true;
      _hasStatsError = false;
      _statsErrorMessage = '';
    });

    final uid = auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isStatsLoading = false;
        _hasStatsError = true;
        _statsErrorMessage = 'User not logged in';
      });
      return;
    }

    try {
      // Fetch order count
      final orderSnapshot =
          await firestore
              .collection('orders')
              .where('userId', isEqualTo: uid)
              .get();

      // Fetch the WishList Count
      final wishlistCount = await getWishlistCount(uid);
      debugPrint('Wishlist count: $wishlistCount');

      final reviewCount = await getReviewsCount(uid);
      debugPrint('Review count: $reviewCount');

      if (mounted) {
        setState(() {
          _orderCount = orderSnapshot.docs.length;
          _wishlistCount = wishlistCount ?? 0;
          _reviewCount = reviewCount ?? 0;
          _isStatsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats data: $e');
      if (mounted) {
        setState(() {
          _isStatsLoading = false;
          _hasStatsError = true;
          _statsErrorMessage = 'Failed to load stats: $e';
        });
      }
    }
  }

  // Refresh all data
  Future<void> _refreshAllData() async {
    await Future.wait([_loadProfileData(), _loadStatsData()]);
  }

  // Function to fetch user profile from Firestore
  Future<void> _showUserProfileModal() async {
    final uid = auth.currentUser?.uid;

    if (uid == null) return;

    final doc = await firestore.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? auth.currentUser!.email!;
    }

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Profile",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Cal_Sans',
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField("Name", _nameController),
              _buildTextField("Email", _emailController, enabled: false),

              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () async {
                    await firestore.collection('users').doc(uid).update({
                      'name': _nameController.text,
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      showSnackBar(
                        context,
                        "Profile updated successfully!",
                        type: SnackBarType.success,
                      );
                      _loadProfileData(); // Refresh profile data only
                    }
                  },
                  child: const Text("Update Profile"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddressModal() async {
    final uid = auth.currentUser?.uid;

    if (uid == null) return;

    final doc = await firestore.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      _phoneController.text = data['phone'] ?? '';
      _addressController.text = data['address'] ?? '';
      _address2Controller.text = data['address2'] ?? '';
      _stateController.text = data['state'] ?? '';
      _cityController.text = data['city'] ?? '';
      _zipCodeController.text = data['zipCode'] ?? '';
    }

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Address Book",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Cal_Sans',
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField("Phone", _phoneController),
              _buildTextField("Address Line 1", _addressController),
              _buildTextField("Address Line 2", _address2Controller),
              _buildTextField("State/Province", _stateController),
              _buildTextField("City", _cityController),
              _buildTextField("Zip/Postal", _zipCodeController),

              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () async {
                    await firestore.collection('users').doc(uid).update({
                      'phone': _phoneController.text,
                      'address': _addressController.text,
                      'address2': _address2Controller.text,
                      'state': _stateController.text,
                      'city': _cityController.text,
                      'zipCode': _zipCodeController.text,
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      showSnackBar(
                        context,
                        "Address updated successfully!",
                        type: SnackBarType.success,
                      );
                      _loadProfileData(); // Refresh profile data only
                    }
                  },
                  child: const Text("Update Address"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPasswordModal() async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Change Password",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Cal_Sans',
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField("New Password", _passwordController),

              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () async {
                    await auth.currentUser?.updatePassword(
                      _passwordController.text,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      showSnackBar(
                        context,
                        "Password updated successfully!",
                        type: SnackBarType.success,
                      );
                    }
                  },
                  child: const Text("Update Password"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Profile",
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontFamily: 'Cal_Sans',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Header with Image - Shows loading state or content
                  _buildProfileHeader(theme),

                  const SizedBox(height: 24),

                  // Stats Section - Independently loaded
                  _buildStatsSection(theme),

                  const SizedBox(height: 24),

                  // Account Settings Section - Only show when profile is loaded
                  if (!_isProfileLoading) ...[
                    Text(
                      "Account Settings",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // User Profile Button
                    _buildProfileOption(
                      icon: Icons.edit,
                      title: "User Profile",
                      subtitle: "Update and view your account details",
                      onTap: _showUserProfileModal,
                    ),

                    // Address Book
                    _buildProfileOption(
                      icon: Icons.location_on_outlined,
                      title: "Address Book",
                      subtitle: "Manage your shipping addresses",
                      onTap: _showAddressModal,
                    ),
                    // Change Password
                    _buildProfileOption(
                      icon: Icons.lock_outlined,
                      title: "Change Password",
                      subtitle: "Change your password",
                      onTap: _showPasswordModal,
                    ),
                    // Order Details
                    _buildProfileOption(
                      icon: Icons.shopping_cart_outlined,
                      title: "Order Details",
                      subtitle: "View your order details",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrdersScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Support Section
                    Text(
                      "Support",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Feedback Button
                    _buildProfileOption(
                      icon: Icons.feedback_outlined,
                      title: "Feedback",
                      subtitle: "Send us your feedback",
                      onTap: () {
                        Navigator.pushNamed(context, '/user_feedback');
                      },
                    ),

                    // View All Feedbacks
                    _buildProfileOption(
                      icon: Icons.rate_review_outlined,
                      title: "View All Feedbacks",
                      subtitle: "View all feedbacks",
                      onTap: () {
                        Navigator.pushNamed(context, '/view_feedback');
                      },
                    ),

                    // Information
                    _buildProfileOption(
                      icon: Icons.info_outline,
                      title: "Information",
                      subtitle: "Learn more about our app",
                      onTap: () {
                        Navigator.pushNamed(context, '/user_info');
                      },
                    ),
                    // FAQ
                    _buildProfileOption(
                      icon: Icons.question_mark_outlined,
                      title: "FAQ",
                      subtitle: "Frequently Asked Questions",
                      onTap: () {
                        Navigator.pushNamed(context, '/user_faq');
                      },
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    _buildProfileOption(
                      icon: Icons.logout_rounded,
                      title: "Logout",
                      subtitle: "Sign out from your account",
                      onTap: () {
                        _showLogoutConfirmationDialog();
                      },
                      iconColor: Colors.red,
                      textColor: Colors.red,
                    ),

                    const SizedBox(height: 24),

                    // App Version
                    Center(
                      child: Text(
                        "Watch Hub v1.0.0",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Show loading indicator for profile content if still loading
                  if (_isProfileLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Loading profile information...",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Profile header section with its own loading state
  Widget _buildProfileHeader(ThemeData theme) {
    if (_isProfileLoading) {
      return Center(
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasProfileError) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 50, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              "Failed to load profile",
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadProfileData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _changeProfileImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage:
                      _profileImageUrl != null
                          ? MemoryImage(base64Decode(_profileImageUrl!))
                          : null,
                  child:
                      _profileImageUrl == null
                          ? Icon(
                            Icons.person,
                            size: 50,
                            color: theme.colorScheme.primary,
                          )
                          : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(_userData?['name'] ?? 'User', style: theme.textTheme.titleLarge),
          Text(
            _userData?['email'] ?? auth.currentUser?.email ?? 'No email',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Use pickedFile.readAsBytes() directly (works on mobile and web)
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _profileImageUrl = base64Image;
      });

      try {
        final uid = auth.currentUser!.uid;
        await firestore.collection('users').doc(uid).update({
          'profileImage': base64Image,
        });
      } catch (e) {
        print('Failed to update profile image: $e');
      }
    }
  }

  // Stats section with its own loading state
  Widget _buildStatsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          _isStatsLoading
              ? _buildStatsLoadingIndicator(theme)
              : _hasStatsError
              ? _buildStatsErrorView(theme)
              : _buildStatsContent(theme),
    );
  }

  // Loading indicator for stats section
  Widget _buildStatsLoadingIndicator(ThemeData theme) {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 30,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 50,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Error view for stats section
  Widget _buildStatsErrorView(ThemeData theme) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 24),
            const SizedBox(height: 8),
            Text(
              "Failed to load stats",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            TextButton(
              onPressed: _loadStatsData,
              child: const Text("Retry"),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Content for stats section when loaded
  Widget _buildStatsContent(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          icon: Icons.shopping_bag_outlined,
          count: _orderCount,
          iconColor: Colors.green,
          label: 'Orders',
          onTap: () {
            Navigator.pushNamed(context, '/orders');
          },
        ),
        _buildDivider(),
        _buildStatItem(
          icon: Icons.favorite_border,
          count: _wishlistCount,
          iconColor: Colors.red,
          label: 'Wishlist',
          onTap: () {
            Navigator.pushNamed(context, '/wishlist');
          },
        ),
        _buildDivider(),
        _buildStatItem(
          icon: Icons.star,
          count: _reviewCount,
          iconColor: Colors.blue,
          label: 'Reviews',
          onTap: () {
            return;
          },
        ),
      ],
    );
  }

  Future<void> _showLogoutConfirmationDialog() async {
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.logout, color: theme.colorScheme.error, size: 24),
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
              'Are you sure you want to logout?',
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
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.3));
  }

  Widget _buildStatItem({
    required IconData icon,
    Color? iconColor,
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? theme.colorScheme.primary).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(color: textColor),
              ),
              subtitle: Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor != null ? textColor.withOpacity(0.7) : null,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: (textColor ?? theme.iconTheme.color)?.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
