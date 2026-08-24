import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookey/models/student.dart';

class StudentService {
  StudentService._();
  static final StudentService instance = StudentService._();

  final _client = Supabase.instance.client;

  Future<List<Student>> fetchStudents(String teacherId) async {
    if (teacherId.trim().isEmpty) return const [];
    final rows = await _client
        .from('students')
        .select()
        .eq('teacher_id', teacherId)
        .order('name');
    return rows.map(Student.fromMap).toList();
  }

  Future<Student> createStudent(String teacherId, String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('name must not be empty');
    }
    final data = await _client
        .from('students')
        .insert({'teacher_id': teacherId, 'name': trimmedName})
        .select()
        .single();
    return Student.fromMap(data);
  }

  Future<void> deleteStudent(String teacherId, String studentId) async {
    await _client
        .from('students')
        .delete()
        .eq('id', studentId)
        .eq('teacher_id', teacherId);
  }
}
