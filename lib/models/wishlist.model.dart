class WishList {
  final String userId;
  final String watchId;

  WishList({required this.userId, required this.watchId});

  factory WishList.fromMap(Map<String, dynamic> map) {
    return WishList(userId: map['userId'] ?? '', watchId: map['watchId'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'watchId': watchId};
  }
}
