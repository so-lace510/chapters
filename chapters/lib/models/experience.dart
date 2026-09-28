class Experience {
  final String id;
  final String title;
  final String body;
  final String? mediaPath;
  final String? mediaType; // 'image' | 'video'
  final DateTime happenedOn;
  final DateTime createdAt;

  const Experience({
    required this.id,
    required this.title,
    required this.body,
    required this.happenedOn,
    required this.createdAt,
    this.mediaPath,
    this.mediaType,
  });

  bool get hasMedia => mediaPath != null && mediaPath!.isNotEmpty;
  bool get isVideo => mediaType == 'video';

  factory Experience.fromMap(Map<String, dynamic> m) => Experience(
        id: m['id'] as String,
        title: m['title'] as String,
        body: m['body'] as String,
        mediaPath: m['media_path'] as String?,
        mediaType: m['media_type'] as String?,
        happenedOn: DateTime.parse(m['happened_on'] as String),
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}
