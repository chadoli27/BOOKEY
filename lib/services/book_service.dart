import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookey/models/book.dart';

class BookService {
  BookService._();
  static final BookService instance = BookService._();

  final _client = Supabase.instance.client;

  Future<List<Book>> fetchBooks(String teacherId) async {
    if (teacherId.trim().isEmpty) return const [];
    final rows = await _client
        .from('books')
        .select()
        .eq('teacher_id', teacherId)
        .order('order_index');
    return rows.map(Book.fromMap).toList();
  }

  Future<Book> createBook(
    String teacherId,
    String title, {
    String? coverUrl,
    int orderIndex = 0,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('title must not be empty');
    }
    final trimmedCoverUrl = coverUrl?.trim();
    final data = await _client
        .from('books')
        .insert({
          'teacher_id': teacherId,
          'title': trimmedTitle,
          'order_index': orderIndex,
          if (trimmedCoverUrl != null && trimmedCoverUrl.isNotEmpty)
            'cover_url': trimmedCoverUrl,
        })
        .select()
        .single();
    return Book.fromMap(data);
  }

  Future<void> deleteBook(String teacherId, String bookId) async {
    await _client
        .from('books')
        .delete()
        .eq('id', bookId)
        .eq('teacher_id', teacherId);
  }
}
