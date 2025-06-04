import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watch_hub/components/snackbar.component.dart';
import 'package:watch_hub/screens/user/checkout_screen.dart';
import 'package:watch_hub/services/cart_service.dart';
import 'package:watch_hub/services/watch_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Services
  final CartService _cartService = CartService();
  final WatchService _watchService = WatchService();

  late final String? userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  double totalPrice = 0.0;
  Map<String, bool> _processingItems = {};

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final items = await _cartService.getCart(userId!);
      final List<Map<String, dynamic>> fullCartItems = [];

      for (var item in items) {
        final String watchId = item['watchId'];

        try {
          final watch = await _watchService.getWatchById(watchId);
          fullCartItems.add({
            ...item,
            'name': watch?['name'],
            'price': watch?['price'],
            'imageUrl': watch?['imageUrl'],
            'stockCount': watch?['stockCount'] ?? 0,
          });
        } catch (e) {
          debugPrint('Error fetching watch $watchId: $e');
          // Optionally skip this item or mark as invalid
        }
      }

      setState(() {
        cartItems = fullCartItems;
        isLoading = false;
        _calculateTotal();
      });
    } catch (e) {
      debugPrint('Error loading cart: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      total +=
          (double.tryParse(item['price'].toString()) ?? 0) * item['quantity'];
    }
    setState(() {
      totalPrice = total;
    });
  }

  // Optimistic update for increasing quantity
  void _increaseQuantity(String watchId) async {
    // Find the item in the cart
    final index = cartItems.indexWhere((item) => item['watchId'] == watchId);
    if (index == -1) return;

    // Check if we're already processing this item
    if (_processingItems[watchId] == true) return;

    final currentQuantity = cartItems[index]['quantity'];
    final availableStock = cartItems[index]['stockCount'] ?? 0;

    // Check stock locally first
    if (currentQuantity >= availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot increase quantity beyond available stock (${availableStock})',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mark item as processing
    setState(() {
      _processingItems[watchId] = true;
      // Update UI immediately
      cartItems[index]['quantity'] += 1;
      _calculateTotal();
    });

    // Update backend
    try {
      await _cartService.increaseQuantity(userId!, watchId);
    } catch (e) {
      // If backend update fails, revert the UI change
      setState(() {
        cartItems[index]['quantity'] -= 1;
        _calculateTotal();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Mark item as no longer processing
      setState(() {
        _processingItems[watchId] = false;
      });
    }
  }

  // Optimistic update for decreasing quantity
  void _decreaseQuantity(String watchId) async {
    // Find the item in the cart
    final index = cartItems.indexWhere((item) => item['watchId'] == watchId);
    if (index == -1) return;

    // Check if we're already processing this item
    if (_processingItems[watchId] == true) return;

    // If quantity is 1, remove the item
    if (cartItems[index]['quantity'] == 1) {
      _removeItem(watchId);
      return;
    }

    // Mark item as processing
    setState(() {
      _processingItems[watchId] = true;
      // Update UI immediately
      cartItems[index]['quantity'] -= 1;
      _calculateTotal();
    });

    // Update backend
    try {
      await _cartService.decreaseQuantity(userId!, watchId);
    } catch (e) {
      // If backend update fails, revert the UI change
      setState(() {
        cartItems[index]['quantity'] += 1;
        _calculateTotal();
      });

      showSnackBar(
        context,
        "Failed to update quantity: ${e.toString()}",
        type: SnackBarType.error,
        showCloseIcon: true,
        duration: const Duration(seconds: 1),
      );
    } finally {
      // Mark item as no longer processing
      setState(() {
        _processingItems[watchId] = false;
      });
    }
  }

  // Optimistic update for removing item
  void _removeItem(String watchId) async {
    // Find the item in the cart
    final index = cartItems.indexWhere((item) => item['watchId'] == watchId);
    if (index == -1) return;

    // Check if we're already processing this item
    if (_processingItems[watchId] == true) return;

    // Store the item in case we need to restore it
    final removedItem = cartItems[index];

    // Mark item as processing and update UI immediately
    setState(() {
      _processingItems[watchId] = true;
      cartItems.removeAt(index);
      _calculateTotal();
    });

    // Update backend
    try {
      await _cartService.removeFromCart(userId!, watchId);
      if (mounted) {
        showSnackBar(
          context,
          "Item removed from cart",
          type: SnackBarType.success,
          showCloseIcon: true,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      // If backend update fails, revert the UI change
      setState(() {
        cartItems.insert(index, removedItem);
        _calculateTotal();
      });

      showSnackBar(
        context,
        "Failed to remove item: ${e.toString()}",
        type: SnackBarType.error,
        showCloseIcon: true,
        duration: const Duration(seconds: 1),
      );
    } finally {
      // Mark item as no longer processing
      setState(() {
        _processingItems[watchId] = false;
      });
    }
  }

  // Add this method to your CartScreen class to navigate to checkout
  void _proceedToCheckout() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                CheckoutScreen(cartItems: cartItems, totalAmount: totalPrice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // More granular screen size detection
    final isVerySmallScreen = screenWidth < 320;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth < 600;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Cart",
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'Cal_Sans',
                  fontSize: isVerySmallScreen ? 24 : null,
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 12 : 16),
              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (cartItems.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: isVerySmallScreen ? 80 : 100,
                          width: isVerySmallScreen ? 80 : 100,
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
                          child: Icon(
                            Icons.remove_shopping_cart,
                            size: isVerySmallScreen ? 40 : 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Your cart is empty",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: isVerySmallScreen ? 18 : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add some watches to get started",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.6,
                            ),
                            fontSize: isVerySmallScreen ? 12 : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final watchId = item['watchId'];
                      final quantity = item['quantity'];
                      final name = item['name'];
                      final price = item['price'];
                      final imageUrl = item['imageUrl'];
                      final stockCount = item['stockCount'] ?? 0;
                      final isProcessing = _processingItems[watchId] == true;
                      final itemTotal =
                          (double.tryParse(price.toString()) ?? 0) * quantity;

                      return Dismissible(
                        key: Key(watchId),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _removeItem(watchId);
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(
                            vertical: isVerySmallScreen ? 6 : 8,
                          ),
                          elevation: 2,
                          child: Stack(
                            children: [
                              // Choose layout based on screen size
                              if (isVerySmallScreen)
                                _buildVeryCompactCartItem(
                                  theme,
                                  watchId,
                                  name,
                                  price,
                                  imageUrl,
                                  quantity,
                                  itemTotal,
                                  stockCount,
                                  isProcessing,
                                )
                              else if (isSmallScreen)
                                _buildCompactCartItem(
                                  theme,
                                  watchId,
                                  name,
                                  price,
                                  imageUrl,
                                  quantity,
                                  itemTotal,
                                  stockCount,
                                  isProcessing,
                                )
                              else
                                _buildRegularCartItem(
                                  theme,
                                  watchId,
                                  name,
                                  price,
                                  imageUrl,
                                  quantity,
                                  itemTotal,
                                  stockCount,
                                  isProcessing,
                                ),
                              if (isProcessing)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.white.withOpacity(0.6),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (!isLoading && cartItems.isNotEmpty) ...[
                SizedBox(height: isVerySmallScreen ? 12 : 16),
                Container(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: isVerySmallScreen ? 18 : null,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              "PKR ${totalPrice.toStringAsFixed(2)}",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                fontSize: isVerySmallScreen ? 18 : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isVerySmallScreen ? 12 : 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _proceedToCheckout(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(
                              vertical: isVerySmallScreen ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "CHECKOUT",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isVerySmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Regular layout for normal screens (unchanged)
  Widget _buildRegularCartItem(
    ThemeData theme,
    String watchId,
    String name,
    dynamic price,
    String imageUrl,
    int quantity,
    double itemTotal,
    int stockCount,
    bool isProcessing,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Watch image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.memory(base64Decode(imageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          // Watch details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "PKR $price",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        "Total: PKR ${itemTotal.toStringAsFixed(2)}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "In stock: $stockCount",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              stockCount > 5
                                  ? Colors.green
                                  : stockCount > 0
                                  ? Colors.orange
                                  : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quantity controls
          _buildQuantityControls(
            theme,
            watchId,
            quantity,
            stockCount,
            isProcessing,
          ),
        ],
      ),
    );
  }

  // Improved compact layout for small screens
  Widget _buildCompactCartItem(
    ThemeData theme,
    String watchId,
    String name,
    dynamic price,
    String imageUrl,
    int quantity,
    double itemTotal,
    int stockCount,
    bool isProcessing,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with image and basic details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Watch image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 65,
                  height: 65,
                  child: Image.memory(
                    base64Decode(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Watch details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "PKR $price",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Stock: $stockCount",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            stockCount > 5
                                ? Colors.green
                                : stockCount > 0
                                ? Colors.orange
                                : Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bottom row with quantity controls and total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total price
              Flexible(
                child: Text(
                  "Total: PKR ${itemTotal.toStringAsFixed(2)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Quantity controls
              _buildQuantityControls(
                theme,
                watchId,
                quantity,
                stockCount,
                isProcessing,
                isCompact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New very compact layout for very small screens
  Widget _buildVeryCompactCartItem(
    ThemeData theme,
    String watchId,
    String name,
    dynamic price,
    String imageUrl,
    int quantity,
    double itemTotal,
    int stockCount,
    bool isProcessing,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with image and name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Watch image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Image.memory(
                    base64Decode(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Watch name and price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "PKR $price",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Middle section with stock info
          Text(
            "Stock: $stockCount",
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  stockCount > 5
                      ? Colors.green
                      : stockCount > 0
                      ? Colors.orange
                      : Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 6),

          // Bottom section with total and quantity controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total price
              Flexible(
                child: Text(
                  "Total: PKR ${itemTotal.toStringAsFixed(2)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Quantity controls
              _buildQuantityControls(
                theme,
                watchId,
                quantity,
                stockCount,
                isProcessing,
                isVeryCompact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable quantity controls widget
  Widget _buildQuantityControls(
    ThemeData theme,
    String watchId,
    int quantity,
    int stockCount,
    bool isProcessing, {
    bool isCompact = false,
    bool isVeryCompact = false,
  }) {
    final buttonSize = isVeryCompact ? 24.0 : (isCompact ? 28.0 : 32.0);
    final iconSize = isVeryCompact ? 12.0 : (isCompact ? 14.0 : 16.0);
    final fontSize = isVeryCompact ? 11.0 : (isCompact ? 13.0 : 16.0);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: IconButton(
              icon: Icon(Icons.remove, size: iconSize),
              onPressed: isProcessing ? null : () => _decreaseQuantity(watchId),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 3 : 4),
            child: Text(
              '$quantity',
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: IconButton(
              icon: Icon(Icons.add, size: iconSize),
              onPressed:
                  isProcessing || quantity >= stockCount
                      ? null
                      : () => _increaseQuantity(watchId),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
