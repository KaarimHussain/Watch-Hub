import 'package:cloud_firestore/cloud_firestore.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the cart document for a specific user
  DocumentReference _userCartRef(String userId) =>
      _firestore.collection('carts').doc(userId);

  // Helper to get watch data (including stock)
  Future<Map<String, dynamic>> _getWatchData(String watchId) async {
    final DocumentSnapshot snapshot =
        await _firestore.collection('watches').doc(watchId).get();
    if (!snapshot.exists) {
      throw Exception('Watch not found');
    }
    return snapshot.data() as Map<String, dynamic>;
  }

  // Add a watch to the user's cart or update quantity if already exists
  Future<void> addToCart(String userId, String watchId) async {
    final DocumentReference cartRef = _userCartRef(userId);
    final DocumentSnapshot cartDoc = await cartRef.get();

    final watchData = await _getWatchData(watchId);
    final int availableStock = watchData['stockCount'] ?? 0;

    if (availableStock <= 0) {
      throw Exception('Selected watch is out of stock');
    }

    List<dynamic> cartItems = [];

    if (cartDoc.exists) {
      final data = cartDoc.data() as Map<String, dynamic>?;
      cartItems = data?['items'] ?? [];
    }

    final existingItemIndex = cartItems.indexWhere(
      (item) => item['watchId'] == watchId,
    );

    if (existingItemIndex != -1) {
      final int currentQty = cartItems[existingItemIndex]['quantity'];

      if (currentQty >= availableStock) {
        throw Exception(
          'Cannot add more. Only $availableStock items left in stock.',
        );
      }

      cartItems[existingItemIndex] = {
        'watchId': watchId,
        'quantity': currentQty + 1,
      };
    } else {
      cartItems.add({'watchId': watchId, 'quantity': 1});
    }

    await cartRef.set({'items': cartItems}, SetOptions(merge: true));
  }

  // Remove a watch from the cart
  Future<void> removeFromCart(String userId, String watchId) async {
    final DocumentReference cartRef = _userCartRef(userId);
    final DocumentSnapshot cartDoc = await cartRef.get();

    if (!cartDoc.exists) return;

    final data = cartDoc.data() as Map<String, dynamic>?;
    final List<dynamic> cartItems = data?['items'] ?? [];

    final updatedItems =
        cartItems.where((item) => item['watchId'] != watchId).toList();

    await cartRef.update({'items': updatedItems});
  }

  // Get the user's cart
  Future<List<Map<String, dynamic>>> getCart(String userId) async {
    final DocumentSnapshot cartDoc = await _userCartRef(userId).get();

    if (!cartDoc.exists) {
      return [];
    }

    final cartData = cartDoc.data() as Map<String, dynamic>?;
    final List<dynamic> cartItems = cartData?['items'] ?? [];
    return cartItems.cast<Map<String, dynamic>>();
  }

  // Decrease & Increase quantity of a watch in the cart
  Future<void> increaseQuantity(String userId, String watchId) async {
    final DocumentReference cartRef = _userCartRef(userId);
    final DocumentSnapshot cartDoc = await cartRef.get();

    if (!cartDoc.exists) return;

    final data = cartDoc.data() as Map<String, dynamic>?;
    final List<dynamic> cartItems = data?['items'] ?? [];

    final int index = cartItems.indexWhere(
      (item) => item['watchId'] == watchId,
    );

    if (index != -1) {
      final watchData = await _getWatchData(watchId);
      final int availableStock = watchData['stockCount'] ?? 0;
      final int currentQty = cartItems[index]['quantity'];

      if (currentQty >= availableStock) {
        throw Exception('Cannot increase quantity beyond available stock.');
      }

      cartItems[index] = {'watchId': watchId, 'quantity': currentQty + 1};

      await cartRef.update({'items': cartItems});
    }
  }

  Future<void> decreaseQuantity(String userId, String watchId) async {
    final DocumentReference cartRef = _userCartRef(userId);
    final DocumentSnapshot cartDoc = await cartRef.get();

    if (!cartDoc.exists) return;

    final data = cartDoc.data() as Map<String, dynamic>?;
    final List<dynamic> cartItems = data?['items'] ?? [];

    final int index = cartItems.indexWhere(
      (item) => item['watchId'] == watchId,
    );

    if (index != -1) {
      final int currentQty = cartItems[index]['quantity'];

      if (currentQty > 1) {
        cartItems[index] = {'watchId': watchId, 'quantity': currentQty - 1};
      } else {
        // Remove item if quantity is 1
        cartItems.removeAt(index);
      }

      await cartRef.update({'items': cartItems});
    }
  }

  // Minus The Stock Count
  Future<void> minusStockCount(
    String userId,
    String watchId,
    int quantity,
  ) async {
    final DocumentReference cartRef = _userCartRef(userId);
    final DocumentSnapshot cartDoc = await cartRef.get();

    if (!cartDoc.exists) return;

    final data = cartDoc.data() as Map<String, dynamic>?;
    final List<dynamic> cartItems = data?['items'] ?? [];

    final int index = cartItems.indexWhere(
      (item) => item['watchId'] == watchId,
    );

    if (index != -1) {
      final watchData = await _getWatchData(watchId);
      final int availableStock = watchData['stockCount'] ?? 0;
      final int currentQty = cartItems[index]['quantity'];

      if (currentQty >= availableStock) {
        throw Exception('Cannot increase quantity beyond available stock.');
      }

      cartItems[index] = {
        'watchId': watchId,
        'quantity': currentQty - quantity,
      };

      await cartRef.update({'items': cartItems});
    }
  }

  // Clear cart
  Future<void> clearCart(String userId) async {
    final DocumentReference cartRef = _userCartRef(userId);
    await cartRef.update({'items': []});
  }
}
