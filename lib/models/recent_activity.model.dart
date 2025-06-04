class RecentActivity {
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;

  RecentActivity({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  // Optional: Factory method for creating from JSON
  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'],
      title: json['title'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Optional: Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
