class StoryModel {
  final String id;
  final String title;
  final String status;
  final String? coverImage;
  final int likesCount;
  final double? rating;
  final DateTime createdAt;

  StoryModel({
    required this.id,
    required this.title,
    required this.status,
    this.coverImage,
    required this.likesCount,
    this.rating,
    required this.createdAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? 'draft',
      coverImage: json['coverImage'],
      likesCount: (json['likesCount'] ?? 0) as int,
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
