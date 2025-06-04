import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/components/average_rating.component.dart';
import 'dart:convert';
import 'dart:ui';

import 'package:watch_hub/services/wishlist_service.dart';

class WatchCard extends StatefulWidget {
  final String watchId;
  final String name;
  final double price;
  final String imageUrl;
  final String category;
  final bool isWishlisted;
  final Function(bool) onWishlistTap;
  final VoidCallback onAddToCartTap;

  const WatchCard({
    super.key,
    required this.watchId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isWishlisted = false,
    required this.onWishlistTap,
    required this.onAddToCartTap,
  });

  @override
  State<WatchCard> createState() => _WatchCardState();
}

class _WatchCardState extends State<WatchCard>
    with SingleTickerProviderStateMixin {
  late bool _isWishlisted;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Add loading state for the Add to Cart button
  bool _isAddingToCart = false;

  double? _averageRating;

  Future<void> _getAverageRating() async {
    debugPrint("Fetching average rating for watchId: ${widget.watchId}");

    try {
      final rating = await getAverageRatingCount(widget.watchId);
      if (mounted) {
        setState(() {
          _averageRating = rating;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch average rating: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _isWishlisted = widget.isWishlisted;
    getWishlistState(widget.watchId);
    _getAverageRating();

    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> getWishlistState(String watchId) async {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() => _isWishlisted = false);
      return;
    }
    final wishlistService = WishlistService();
    bool isWishlistData = await wishlistService.getWishlist(watchId);

    setState(() {
      _isWishlisted = isWishlistData;
    });
  }

  void _handleWishlistTap() {
    final newState = !_isWishlisted;
    setState(() {
      _isWishlisted = newState;
    });
    widget.onWishlistTap(newState);
  }

  // Handle add to cart with loading state
  void _handleAddToCart() async {
    setState(() {
      _isAddingToCart = true;
    });

    try {
      // Call the original onAddToCartTap callback
      widget.onAddToCartTap();

      // Add a small delay to show the loading state
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      // Ensure we reset the loading state even if there's an error
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image with overlay elements
              Stack(
                children: [
                  // Background gradient for image
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey.shade100, Colors.grey.shade200],
                      ),
                    ),
                  ),

                  // Product image
                  Hero(
                    tag: 'watch-${widget.watchId}',
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: Image.memory(
                          base64Decode(widget.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Gradient overlay for better text visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),

                  // Category badge with glassmorphism effect
                  Positioned(
                    top: 16,
                    left: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Wishlist button with animation
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        _handleWishlistTap();
                      },
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0.0,
                          end: _isWishlisted ? 1.0 : 0.0,
                        ),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                Colors.white,
                                Colors.red.shade50,
                                value,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Color.lerp(
                                Colors.grey.shade600,
                                Colors.red,
                                value,
                              ),
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Product name overlay at bottom of image
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      widget.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Product details section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price and rating row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price with accent line
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PKR ${widget.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Container(
                              height: 3,
                              width: 40,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),

                        // Rating pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _averageRating != null
                                    ? _averageRating!.toStringAsFixed(1)
                                    : '0.0',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Add to cart button with gradient and loading state
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isAddingToCart ? null : _handleAddToCart,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Color.lerp(
                                  Theme.of(context).primaryColor,
                                  Colors.black,
                                  0.2,
                                )!,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child:
                                _isAddingToCart
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.shopping_bag_outlined,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Add to Cart',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
