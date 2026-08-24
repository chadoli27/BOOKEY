class Student {
  final String id;
  final String teacherId;
  final String name;

  const Student({required this.id, required this.teacherId, required this.name});

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      teacherId: map['teacher_id'] as String,
      name: (map['name'] as String?) ?? '',
    );
  }
}
