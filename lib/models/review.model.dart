class ReviewModel {
  final String? id;
  final String? watchId;
  final String title;
  final String description;
  final double rating;

  ReviewModel({
    this.id,
    this.watchId,
    required this.title,
    required this.description,
    required this.rating,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ReviewModel(
      id: id,
      watchId: map['watchId'],
      title: map['title'],
      description: map['description'],
      rating: map['rating'].toDouble(),
    );
  }
}
