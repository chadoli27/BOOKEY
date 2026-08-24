import 'package:flutter/material.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/models/student.dart';
import 'package:bookey/services/student_service.dart';

class StudentManagementScreen extends StatefulWidget {
  final String teacherId;

  const StudentManagementScreen({super.key, required this.teacherId});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _service = StudentService.instance;
  final _nameController = TextEditingController();
  bool _isAdding = false;
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _service.fetchStudents(widget.teacherId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _studentsFuture = _service.fetchStudents(widget.teacherId);
    });
  }

  Future<void> _addStudent() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      await _service.createStudent(widget.teacherId, name);
      _nameController.clear();
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('학생 등록 실패: $e')));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _confirmDelete(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학생 삭제'),
        content: Text('${student.name} 학생을 삭제할까요?\n체크된 독서 기록도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteStudent(widget.teacherId, student.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학생 관리')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addStudent(),
                    decoration: const InputDecoration(
                      labelText: '학생 이름',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isAdding ? null : _addStudent,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('등록'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Student>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('불러오기 실패: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final students = snapshot.data!;
                if (students.isEmpty) {
                  return Center(
                    child: Text(
                      '등록된 학생이 없습니다.',
                      style: TextStyle(color: ink.withValues(alpha: 0.5)),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: students.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Dismissible(
                      key: ValueKey(student.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await _confirmDelete(student);
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accentPurple,
                          child: Text(
                            student.name.isNotEmpty
                                ? student.name.substring(0, 1)
                                : '?',
                            style: const TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(student.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _confirmDelete(student),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
