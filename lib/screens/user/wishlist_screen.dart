import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watch_hub/models/watches.model.dart';
import 'package:watch_hub/models/wishlist.model.dart';
import 'package:watch_hub/screens/user/product_details_screen.dart';
import 'package:watch_hub/services/cart_service.dart';
import 'package:watch_hub/services/wishlist_service.dart';
import 'package:watch_hub/components/snackbar.component.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // Service
  final CartService _cartService = CartService();

  List<Watch> _wishlistWatches = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final wishlistEntries = await WishlistService().getWishlistByUser(
        user.uid,
      );
      final List<Watch> watches = [];

      for (var entry in wishlistEntries) {
        final watchDoc =
            await FirebaseFirestore.instance
                .collection('watches')
                .doc(entry['watchId'])
                .get();

        if (watchDoc.exists) {
          watches.add(
            Watch(
              id: watchDoc.id,
              name: watchDoc['name'],
              price: (watchDoc['price'] as num).toDouble(), // <-- Fix here
              category: watchDoc['category'],
              description: watchDoc['description'],
              imageUrl: watchDoc['imageUrl'],
              stockCount: watchDoc['stockCount'],
              model: watchDoc['model'],
              movementType: watchDoc['movementType'],
              caseMaterial: watchDoc['caseMaterial'],
              diameter:
                  (watchDoc['diameter'] as num).toDouble(), // <-- Fix here
              thickness:
                  (watchDoc['thickness'] as num).toDouble(), // <-- Fix here
              bandMaterial: watchDoc['bandMaterial'],
              bandWidth:
                  (watchDoc['bandWidth'] as num).toDouble(), // <-- Fix here
              weight: (watchDoc['weight'] as num).toDouble(), // <-- Fix here
              warranty: watchDoc['warranty'],
              specialFeature: watchDoc['specialFeature'],
              waterResistant: watchDoc['waterResistant'],
            ),
          );
        }
      }

      setState(() {
        _wishlistWatches = watches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load wishlist: $e';
      });
    }
  }

  Future<bool> _removeFromWishlist(String watchId, int index) async {
    setState(() {
      _wishlistWatches.removeWhere((watch) => watch.id == watchId);
    });
    final wishlistData = WishList(
      userId: FirebaseAuth.instance.currentUser!.uid,
      watchId: watchId,
    );

    final success = await WishlistService().removeWishlist(wishlistData);

    if (success) {
      showSnackBar(
        context,
        'Removed from wishlist',
        type: SnackBarType.success,
      );
    } else {
      showSnackBar(context, 'Failed to remove item', type: SnackBarType.error);
    }

    return success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchWishlist,
        color: theme.colorScheme.primary,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Wishlist",
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontFamily: 'Cal_Sans',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _wishlistWatches.isEmpty
                              ? "You haven't added any watches yet"
                              : "${_wishlistWatches.length} ${_wishlistWatches.length == 1 ? 'watch' : 'watches'} in your wishlist",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!_isLoading &&
                        !_hasError &&
                        _wishlistWatches.isNotEmpty)
                      IconButton(
                        onPressed: _fetchWishlist,
                        icon: const Icon(Icons.refresh_outlined),
                        tooltip: 'Refresh',
                      ),
                  ],
                ),
              ),
              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Divider(height: 1, color: theme.dividerTheme.color),
              ),

              // Main content
              Expanded(child: _buildContent(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Loading your wishlist...",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchWishlist,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_wishlistWatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF000000), // Pure black
                      Color(0xFF333333), // Dark gray
                      Color(0xFF555555), // Medium gray
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your wishlist is empty',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Add watches to your wishlist to keep track of items you love',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to catalog/home screen
                  Navigator.of(context).pushReplacementNamed('/user_home');
                },
                icon: const Icon(Icons.watch_outlined),
                label: const Text('Browse Watches'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Enhanced wishlist items list
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _wishlistWatches.length,
      itemBuilder: (context, index) {
        final watch = _wishlistWatches[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildWishlistCard(watch, index, theme),
        );
      },
    );
  }

  Widget _buildWishlistCard(Watch watch, int index, ThemeData theme) {
    final bool isInStock = watch.stockCount > 0;

    return Dismissible(
      key: Key(watch.id.toString()), // Unique key for each item
      direction: DismissDirection.horizontal, // Swipe horizontally
      background: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        // Call existing removal logic and return success status
        return await _removeFromWishlist(watch.id.toString(), index);
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.dividerTheme.color ?? Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(watch: watch),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced image container
                Hero(
                  tag: 'wishlist-${watch.id}',
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dividerTheme.color ?? Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(watch.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            child: Center(
                              child: Icon(
                                Icons.watch_outlined,
                                size: 40,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Enhanced details section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category with subtle styling
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          watch.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Watch name
                      Text(
                        watch.name,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Cal_Sans",
                          fontSize: 17,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Price with better styling
                      Text(
                        "PKR ${watch.price.toStringAsFixed(0)}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Stock indicator with better styling
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isInStock ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isInStock
                                ? "In Stock (${watch.stockCount})"
                                : "Out of Stock",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isInStock ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Action buttons with better styling
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  isInStock
                                      ? () {
                                        // Add to cart logic
                                        _cartService.addToCart(
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                          watch.id!,
                                        );
                                        // Remove the item from the wishlist
                                        _removeFromWishlist(
                                          watch.id.toString(),
                                          index,
                                        );
                                        showSnackBar(
                                          context,
                                          '${watch.name} added to cart',
                                          type: SnackBarType.success,
                                        );
                                      }
                                      : null,
                              icon: const Icon(
                                Icons.shopping_cart_outlined,
                                size: 18,
                              ),
                              label: const Text('Add to Cart'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Remove from wishlist button with better styling
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.favorite_rounded,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              onPressed: () async {
                                await _removeFromWishlist(
                                  watch.id.toString(),
                                  index,
                                );
                              },
                              tooltip: 'Remove from wishlist',
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
