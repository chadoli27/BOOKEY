import 'package:supabase_flutter/supabase_flutter.dart';

/// One `book_reads` row, joined with the student/book names it points at —
/// used to drive the admin dashboard's stats and activity feed.
class BookReadEntry {
  final String studentId;
  final String studentName;
  final String bookId;
  final String bookTitle;
  final DateTime checkedAt;

  const BookReadEntry({
    required this.studentId,
    required this.studentName,
    required this.bookId,
    required this.bookTitle,
    required this.checkedAt,
  });
}

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

  /// All read checks for a teacher's roster, newest first — the source data
  /// for the dashboard's stat tiles, recent-activity feed, and each
  /// student/book's read count.
  Future<List<BookReadEntry>> fetchReadsForTeacher(String teacherId) async {
    final rows = await _client
        .from('book_reads')
        .select('student_id, book_id, checked_at, students(name), books(title)')
        .eq('teacher_id', teacherId)
        .order('checked_at', ascending: false);
    return rows.map((row) {
      final student = row['students'] as Map<String, dynamic>?;
      final book = row['books'] as Map<String, dynamic>?;
      return BookReadEntry(
        studentId: row['student_id'] as String,
        studentName: (student?['name'] as String?) ?? '',
        bookId: row['book_id'] as String,
        bookTitle: (book?['title'] as String?) ?? '',
        checkedAt: DateTime.parse(row['checked_at'] as String),
      );
    }).toList();
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
