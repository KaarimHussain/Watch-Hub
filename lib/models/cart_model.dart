class Cart {
  final String userId;
  final List<String> watchIds;

  Cart({required this.userId, required this.watchIds});

  factory Cart.fromMap(Map<String, dynamic> map) {
    return Cart(
      userId: map['userId'],
      watchIds: List<String>.from(map['watchIds']),
    );
  }
}
