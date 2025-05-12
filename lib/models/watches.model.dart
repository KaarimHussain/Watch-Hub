class Watch {
  final String? id;
  final String name;
  final double price;
  final String category;
  final String description;
  final String imageUrl;
  final int stockCount;

  Watch({
    this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.stockCount,
  });

  factory Watch.fromMap(Map<String, dynamic> map, {String? id}) {
    return Watch(
      id: id,
      name: map['name'],
      price: map['price'].toDouble(),
      category: map['category'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      stockCount: map['stockCount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'stockCount': stockCount,
    };
  }
}
