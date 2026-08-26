/// Mirrors `public.teachers`. Email isn't stored here — it lives on
/// `auth.users` and is read from the active Supabase Auth session instead.
class TeacherProfile {
  final String id;
  final String name;

  const TeacherProfile({required this.id, required this.name});

  factory TeacherProfile.fromMap(Map<String, dynamic> map) {
    return TeacherProfile(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
    );
  }
}
