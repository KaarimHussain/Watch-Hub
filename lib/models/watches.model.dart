class Watch {
  final String? id;
  final String name;
  final double price;
  final String category;
  final String description;
  final String imageUrl;
  final int stockCount;
  final String model;
  final String movementType;
  final String caseMaterial;
  final double diameter;
  final double thickness;
  final bool waterResistant;
  final String bandMaterial;
  final double bandWidth;
  final double weight;
  final int warranty;
  final String specialFeature;

  Watch({
    this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.stockCount,
    required this.model,
    required this.movementType,
    required this.caseMaterial,
    required this.diameter,
    required this.thickness,
    required this.waterResistant,
    required this.bandMaterial,
    required this.bandWidth,
    required this.weight,
    required this.warranty,
    required this.specialFeature,
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
      model: map['model'],
      movementType: map['movementType'],
      caseMaterial: map['caseMaterial'],
      diameter: map['diameter'].toDouble(),
      thickness: map['thickness'].toDouble(),
      waterResistant: map['waterResistant'],
      bandMaterial: map['bandMaterial'],
      bandWidth: map['bandWidth'].toDouble(),
      weight: map['weight'].toDouble(),
      warranty: map['warranty'],
      specialFeature: map['specialFeature'],
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
      'model': model,
      'movementType': movementType,
      'caseMaterial': caseMaterial,
      'diameter': diameter,
      'thickness': thickness,
      'waterResistant': waterResistant,
      'bandMaterial': bandMaterial,
      'bandWidth': bandWidth,
      'weight': weight,
      'warranty': warranty,
      'specialFeature': specialFeature,
    };
  }
}
