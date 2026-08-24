import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks which books a student has checked off as read. A row's mere
/// existence in `book_reads` means "read" — there's no boolean column.
class BookReadService {
  BookReadService._();
  static final BookReadService instance = BookReadService._();

  final _client = Supabase.instance.client;

  Future<Set<String>> fetchReadBookIds(String studentId) async {
    final rows = await _client
        .from('book_reads')
        .select('book_id')
        .eq('student_id', studentId);
    return rows.map((row) => row['book_id'] as String).toSet();
  }

  Future<void> markRead({
    required String teacherId,
    required String studentId,
    required String bookId,
  }) async {
    await _client.from('book_reads').upsert({
      'teacher_id': teacherId,
      'student_id': studentId,
      'book_id': bookId,
    }, onConflict: 'student_id,book_id');
  }

  Future<void> markUnread({
    required String studentId,
    required String bookId,
  }) async {
    await _client
        .from('book_reads')
        .delete()
        .eq('student_id', studentId)
        .eq('book_id', bookId);
  }
}
