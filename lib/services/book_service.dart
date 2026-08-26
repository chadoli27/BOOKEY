import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookey/models/book.dart';

const _coverBucket = 'book-covers';

class BookService {
  BookService._();
  static final BookService instance = BookService._();

  final _client = Supabase.instance.client;

  /// 표지 이미지를 Supabase Storage(`book-covers` 버킷)에 업로드하고
  /// 공개 URL을 반환한다. 선생님 폴더(teacherId) 아래에 저장한다.
  Future<String> uploadCoverImage(
    String teacherId,
    Uint8List bytes,
    String fileName,
  ) async {
    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        : 'jpg';
    final path =
        '$teacherId/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _client.storage
        .from(_coverBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeFor(ext),
            upsert: true,
          ),
        );
    return _client.storage.from(_coverBucket).getPublicUrl(path);
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

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

  Future<Book> updateBook(
    String teacherId,
    String bookId,
    String title, {
    String? coverUrl,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('title must not be empty');
    }
    final trimmedCoverUrl = coverUrl?.trim();
    final data = await _client
        .from('books')
        .update({
          'title': trimmedTitle,
          'cover_url': (trimmedCoverUrl != null && trimmedCoverUrl.isNotEmpty)
              ? trimmedCoverUrl
              : null,
        })
        .eq('id', bookId)
        .eq('teacher_id', teacherId)
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
