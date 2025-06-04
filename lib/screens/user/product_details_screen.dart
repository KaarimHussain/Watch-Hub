import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/models/watches.model.dart';
import 'package:watch_hub/screens/user/image_view_screen.dart';
import 'package:watch_hub/screens/user/view_review_screen.dart';
import 'package:watch_hub/services/cart_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.watch});

  final Watch watch;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  // Collection Reference
  final CollectionReference _reviewsCollection = FirebaseFirestore.instance
      .collection('reviews');

  // Service
  final CartService _cartService = CartService();

  int _rating = 0;
  int _averageRating = 0;
  String? id;

  // Add to cart button state
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    id = widget.watch.id;
    _getReviewsCount();
    _getAverageRatingCount(widget.watch.id);
  }

  Future<void> _getReviewsCount() async {
    try {
      final QuerySnapshot querySnapshot =
          await _reviewsCollection
              .where('watchId', isEqualTo: widget.watch.id)
              .get();
      setState(() {
        _rating = querySnapshot.docs.length;
      });
    } catch (e) {
      debugPrint('Error fetching reviews count: $e');
    }
  }

  Future<void> _getAverageRatingCount(String? watchId) async {
    double averageRating = 0.0;
    if (watchId == null) return;
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('reviews')
            .where('watchId', isEqualTo: watchId)
            .get();

    if (snapshot.docs.isNotEmpty) {
      double total = 0.0;

      for (var doc in snapshot.docs) {
        total += (doc['rating'] ?? 0).toDouble();
      }

      averageRating = total / snapshot.docs.length;
    }

    setState(() {
      _averageRating = averageRating.toInt();
    });
  }

  // Add to cart with simplified state management
  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSnackBar(
        context,
        "Please login to add items to cart",
        type: SnackBarType.error,
      );
      return;
    }

    // Set loading state
    setState(() {
      _isAddingToCart = true;
    });

    try {
      await _cartService.addToCart(user.uid, widget.watch.id.toString());

      if (!mounted) return;

      // Return to normal state after adding to cart
      setState(() {
        _isAddingToCart = false;
      });

      showSnackBar(context, "Watch added to cart", type: SnackBarType.success);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAddingToCart = false;
      });

      showSnackBar(context, e.toString(), type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'Watch Details',
          style: theme.textTheme.titleLarge?.copyWith(fontFamily: 'Cal_Sans'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Section
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Image container with shimmer loading effect
                    Container(
                      height: 300,
                      width: double.infinity,
                      color: theme.cardTheme.color,
                      child: Hero(
                        tag: 'watch-image-${widget.watch.id}',
                        child: Image.memory(
                          base64Decode(widget.watch.imageUrl),
                          fit: BoxFit.contain,
                          frameBuilder: (
                            context,
                            child,
                            frame,
                            wasSynchronouslyLoaded,
                          ) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              return child;
                            }
                            return ShimmerLoading(
                              isLoading: true,
                              child: Container(
                                height: 300,
                                width: double.infinity,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              width: double.infinity,
                              color: theme.colorScheme.surface,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_rounded,
                                    size: 64,
                                    color: theme.colorScheme.error.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Image not available',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Gradient overlay at the top for better icon visibility
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.background.withOpacity(0.5),
                              theme.colorScheme.background.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Preview button with improved styling
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: theme.colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ImageViewScreen(
                                      imageUrl: widget.watch.imageUrl,
                                      heroTag: 'watch-image-${widget.watch.id}',
                                      title:
                                          widget
                                              .watch
                                              .name, // Optionally pass the watch name as the title
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.zoom_in_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Preview',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tap anywhere indicator
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap image to enlarge',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Make the entire image clickable
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: theme.colorScheme.primary.withOpacity(
                            0.1,
                          ),
                          highlightColor: Colors.transparent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ImageViewScreen(
                                      imageUrl: widget.watch.imageUrl,
                                      heroTag: 'watch-image-${widget.watch.id}',
                                      title:
                                          widget
                                              .watch
                                              .name, // Optionally pass the watch name as the title
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Product Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      widget.watch.category,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Product Name
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Watch name and stock indicator
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.watch.name,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontFamily: 'Cal_Sans',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    widget.watch.stockCount > 5
                                        ? theme.colorScheme.primary.withOpacity(
                                          0.1,
                                        )
                                        : widget.watch.stockCount != 0
                                        ? Colors.orangeAccent.withValues(
                                          alpha: 0.1,
                                        )
                                        : theme.colorScheme.error.withValues(
                                          alpha: 0.1,
                                        ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.watch.stockCount != 0
                                    ? widget.watch.stockCount > 5
                                        ? 'In Stock: ${widget.watch.stockCount}'
                                        : 'Low Stock: ${widget.watch.stockCount}'
                                    : 'Out of Stock',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      widget.watch.stockCount != 0
                                          ? widget.watch.stockCount > 5
                                              ? theme.colorScheme.primary
                                              : Colors.orangeAccent
                                          : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Divider
                        Divider(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),

                        const SizedBox(height: 16),

                        // Price and rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Price with currency
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PKR ${widget.watch.price.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontFamily: 'Cal_Sans',
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),

                            // Rating with stars
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rating',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '$_averageRating',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .secondary,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Row(
                                            children: List.generate(5, (index) {
                                              if (index < _averageRating) {
                                                return Icon(
                                                  Icons.star_rounded,
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .secondary,
                                                  size: 18,
                                                );
                                              } else {
                                                return Icon(
                                                  Icons.star_outline_rounded,
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .secondary,
                                                  size: 18,
                                                );
                                              }
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Header
                  Text(
                    'Description',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'Cal_Sans',
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    widget.watch.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  // Watch Specifications Section
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "Specifications",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'Cal_Sans',
                            ),
                          ),
                        ),
                        Divider(color: theme.dividerColor, height: 1),
                        // Basic Info Section
                        _buildSpecCategory("Basic Information", [
                          _buildSpecItem(
                            Icons.watch,
                            "Model",
                            widget.watch.model,
                          ),
                          _buildSpecItem(
                            Icons.settings,
                            "Movement Type",
                            widget.watch.movementType,
                          ),
                        ]),
                        // Case Details Section
                        _buildSpecCategory("Case Details", [
                          _buildSpecItem(
                            Icons.diamond_outlined,
                            "Case Material",
                            widget.watch.caseMaterial,
                          ),
                          _buildSpecItem(
                            Icons.radio_button_unchecked,
                            "Diameter",
                            widget.watch.diameter.toString(),
                          ),
                          _buildSpecItem(
                            Icons.height,
                            "Thickness",
                            widget.watch.thickness.toString(),
                          ),
                          _buildSpecItem(
                            Icons.water_drop_outlined,
                            "Water Resistant",
                            widget.watch.waterResistant ? 'Yes' : 'No',
                          ),
                        ]),
                        // Band Details Section
                        _buildSpecCategory("Band Details", [
                          _buildSpecItem(
                            Icons.watch_outlined,
                            "Band Material",
                            widget.watch.bandMaterial,
                          ),
                          _buildSpecItem(
                            Icons.straighten,
                            "Band Width",
                            widget.watch.bandWidth.toString(),
                          ),
                        ]),
                        // Additional Info Section
                        _buildSpecCategory("Additional Information", [
                          _buildSpecItem(
                            Icons.scale,
                            "Weight",
                            widget.watch.weight.toString(),
                          ),
                          _buildSpecItem(
                            Icons.verified_outlined,
                            "Warranty",
                            widget.watch.warranty.toString(),
                          ),
                          _buildSpecItem(
                            Icons.star_outline,
                            "Special Features",
                            widget.watch.specialFeature,
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Reviews",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'Cal_Sans',
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ViewReviewScreen(
                                    watchId: widget.watch.id,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "See all (${_rating.toString()})",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: theme.iconTheme.color,
                                size: 14,
                              ),
                            ],
                          ),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.bottomAppBarTheme.color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Price display in bottom bar
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'PKR ${widget.watch.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Add to cart button with simplified state
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed:
                    widget.watch.stockCount > 0
                        ? (_isAddingToCart ? null : _addToCart)
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child:
                    _isAddingToCart
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : widget.watch.stockCount <= 0
                        ? const Text('Out of Stock')
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.shopping_cart, size: 18),
                            SizedBox(width: 8),
                            Text('Add to Cart'),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a specification category
  Widget _buildSpecCategory(String title, List<Widget> items) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items,
        Divider(
          color: theme.dividerColor,
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }

  // Helper method to build a specification item
  Widget _buildSpecItem(IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.iconTheme.color),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Add this ShimmerLoading widget to your code
class ShimmerLoading extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const ShimmerLoading({Key? key, required this.isLoading, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: child,
    );
  }
}
