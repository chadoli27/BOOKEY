import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookey/models/teacher_profile.dart';

class TeacherService {
  TeacherService._();
  static final TeacherService instance = TeacherService._();

  final _db = Supabase.instance.client.from('teachers');

  Future<TeacherProfile> ensureTeacher(String teacherId, {String? name}) async {
    final trimmed = teacherId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('teacherId must not be empty');
    }

    final trimmedName = name?.trim();
    await _db.upsert({
      'id': trimmed,
      if (trimmedName != null && trimmedName.isNotEmpty) 'name': trimmedName,
    }, onConflict: 'id', ignoreDuplicates: true);
    final data = await _db.select().eq('id', trimmed).single();
    return TeacherProfile.fromMap(data);
  }

  Future<TeacherProfile> updateName(String teacherId, String name) async {
    final trimmedId = teacherId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('teacherId must not be empty');
    }
    final data = await _db
        .update({'name': name.trim()})
        .eq('id', trimmedId)
        .select()
        .single();
    return TeacherProfile.fromMap(data);
  }
}
