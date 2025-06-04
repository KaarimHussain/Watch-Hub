import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/models/recent_activity.model.dart';
import 'package:watch_hub/models/signup.model.dart';
import 'package:watch_hub/screens/admin/admin_drawer.dart';
import 'package:watch_hub/screens/admin/user_detail_screen.dart';
import 'package:watch_hub/services/recent_activity_service.dart';

class UserListScreen extends StatelessWidget {
  UserListScreen({super.key});

  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );
  final RecentActivityService _recentActivityService = RecentActivityService();

  // Enhanced delete function with comprehensive data removal
  Future<void> _deleteUser(BuildContext context, String userId) async {
    try {
      // Confirmation dialog with improved styling
      bool confirm = await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                "Delete User",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                "Are you sure you want to delete this user? This will permanently remove all user data including orders, cart items, reviews, and wishlist. This action cannot be undone.",
                style: TextStyle(height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Delete All Data"),
                ),
              ],
            ),
      );

      if (confirm == true) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Deleting user data..."),
                ],
              ),
            );
          },
        );

        // Comprehensive user data deletion
        await _deleteAllUserData(userId);

        // Close loading dialog
        Navigator.of(context).pop();

        // Add recent activity
        await _recentActivityService.addRecentActivity(
          RecentActivity(
            title: "User deleted",
            type: "User",
            timestamp: DateTime.now(),
            description: "User and all associated data deleted successfully",
          ),
        );

        // Show success snackbar
        showSnackBar(
          context,
          "User and all associated data deleted successfully",
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.of(context, rootNavigator: true).pop();

      // Error snackbar with improved styling
      showSnackBar(
        context,
        "Failed to delete user: $e",
        type: SnackBarType.error,
      );
    }
  }

  // Comprehensive user data deletion from all collections
  Future<void> _deleteAllUserData(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final WriteBatch batch = firestore.batch();

    try {
      // 1. Delete from Cart collection
      await _deleteFromCollection('carts', 'userId', userId, batch);

      // 2. Delete from Feedback collection
      await _deleteFromCollection('feedback', 'userId', userId, batch);

      // 3. Delete from Orders collection
      await _deleteFromCollection('orders', 'userId', userId, batch);

      // 4. Delete from Perfect_collection collection
      await _deleteFromCollection(
        'perfect_collection',
        'userId',
        userId,
        batch,
      );

      // 5. Delete from recentActivity collection (if user-specific)
      await _deleteFromCollection('recentActivity', 'userId', userId, batch);

      // 6. Delete from reviews collection
      await _deleteFromCollection('reviews', 'userId', userId, batch);

      // 7. Delete from wishlist collection
      await _deleteFromCollection('wishlist', 'userId', userId, batch);

      // 8. Delete from watches collection (if user is the owner/creator)
      await _deleteFromCollection('watches', 'createdBy', userId, batch);
      // Also delete watches where user might be referenced in other fields
      await _deleteFromCollection('watches', 'userId', userId, batch);

      // 9. Finally, delete from users collection
      batch.delete(firestore.collection('users').doc(userId));

      // Execute all deletions in a single batch
      await batch.commit();

      // Additional cleanup for any remaining references
      await _cleanupRemainingReferences(userId);
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  // Helper method to delete documents from a collection based on a field
  Future<void> _deleteFromCollection(
    String collectionName,
    String fieldName,
    String userId,
    WriteBatch batch,
  ) async {
    try {
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection(collectionName)
              .where(fieldName, isEqualTo: userId)
              .get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      print('Error deleting from $collectionName: $e');
      // Continue with other deletions even if one fails
    }
  }

  // Additional cleanup for any remaining references
  Future<void> _cleanupRemainingReferences(String userId) async {
    try {
      // Clean up any subcollections or nested references

      // Example: Clean up user references in watch reviews subcollection
      final watchesSnapshot =
          await FirebaseFirestore.instance.collection('watches').get();

      for (var watchDoc in watchesSnapshot.docs) {
        // Delete user reviews in watch subcollections
        final reviewsSnapshot =
            await watchDoc.reference
                .collection('reviews')
                .where('userId', isEqualTo: userId)
                .get();

        for (var reviewDoc in reviewsSnapshot.docs) {
          await reviewDoc.reference.delete();
        }

        // Delete user ratings in watch subcollections
        final ratingsSnapshot =
            await watchDoc.reference
                .collection('ratings')
                .where('userId', isEqualTo: userId)
                .get();

        for (var ratingDoc in ratingsSnapshot.docs) {
          await ratingDoc.reference.delete();
        }
      }

      // Clean up user references in order items or any other nested structures
      final ordersSnapshot =
          await FirebaseFirestore.instance.collection('Orders').get();

      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();

        // If order has items with user references, clean them up
        if (orderData['items'] != null) {
          List<dynamic> items = orderData['items'];
          bool hasUserReference = items.any(
            (item) =>
                item is Map &&
                (item['userId'] == userId || item['addedBy'] == userId),
          );

          if (hasUserReference) {
            // Remove items added by this user or update the order
            List<dynamic> updatedItems =
                items
                    .where(
                      (item) =>
                          !(item is Map &&
                              (item['userId'] == userId ||
                                  item['addedBy'] == userId)),
                    )
                    .toList();

            if (updatedItems.isEmpty) {
              // If no items left, delete the entire order
              await orderDoc.reference.delete();
            } else {
              // Update the order with remaining items
              await orderDoc.reference.update({'items': updatedItems});
            }
          }
        }
      }
    } catch (e) {
      print('Error in cleanup: $e');
      // Don't throw error for cleanup failures
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final theme = Theme.of(context);
    final darkGray = theme.colorScheme.primary;
    final mediumGray = theme.colorScheme.secondary;
    final lightGray = const Color(0xFFCED4DA);

    return Scaffold(
      drawer: AdminDrawer(selectedIndex: 3),
      appBar: AppBar(
        title: const Text('Users Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('User Management'),
                      content: const Text(
                        'Deleting a user will permanently remove:\n\n'
                        '• User account and profile\n'
                        '• All orders and order history\n'
                        '• Cart items and wishlist\n'
                        '• Reviews and feedback\n'
                        '• Any watches created by the user\n'
                        '• All associated activity logs\n\n'
                        'This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: users.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error fetching users',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // This would refresh the page
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: darkGray,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Loading users...", style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          final userDocs = snapshot.data!.docs;

          if (userDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: mediumGray),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              var user = userDocs[index].data() as Map<String, dynamic>;
              var docId = userDocs[index].id;
              final myUser = SignupModel(
                name: user['name'] ?? 'User',
                email: user['email'] ?? 'No Email',
                password: user['password'] ?? 'No Password',
                role: user['role'] ?? 'User',
                address: user['address'] ?? 'No Address',
                phone: user['phone'] ?? 'No Phone',
                createdAt: user['createdAt'] ?? Timestamp.now(),
              );

              // Generate a consistent color based on the user's name
              final String name = user['name'] ?? 'User';
              final int colorValue = name.hashCode % Colors.primaries.length;
              final Color avatarColor = Colors.primaries[colorValue];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: lightGray, width: 1),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailScreen(user: myUser),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar with subtle styling
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: avatarColor.withValues(alpha: 0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: avatarColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user['name'] ?? 'No Name',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: mediumGray,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      user['email'] ?? 'No Email',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (user['phone'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: mediumGray,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      user['phone'],
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Prevent deletion of admin users
                        if (user['role'] != 'admin')
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _deleteUser(context, docId),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: theme.colorScheme.error,
                                  size: 22,
                                ),
                              ),
                            ),
                          )
                        else
                          // Show protected icon for admin users
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: Colors.orange,
                              size: 22,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
