class Book {
  final String id;
  final String teacherId;
  final String title;
  final String? coverUrl;
  final int orderIndex;

  const Book({
    required this.id,
    required this.teacherId,
    required this.title,
    this.coverUrl,
    this.orderIndex = 0,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      teacherId: map['teacher_id'] as String,
      title: (map['title'] as String?) ?? '',
      coverUrl: map['cover_url'] as String?,
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
    );
  }
}
