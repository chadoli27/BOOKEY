import 'package:flutter/material.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/models/student.dart';
import 'package:bookey/screens/student_books_screen.dart';
import 'package:bookey/services/student_service.dart';

/// 학생용 키오스크 화면 진입점. 로그인된 선생님 계정 위에서 학생 이름만
/// 골라 들어가는 화면 — 별도 인증 없음 (PRD 5.2).
class StudentSelectScreen extends StatefulWidget {
  final String teacherId;

  const StudentSelectScreen({super.key, required this.teacherId});

  @override
  State<StudentSelectScreen> createState() => _StudentSelectScreenState();
}

class _StudentSelectScreenState extends State<StudentSelectScreen> {
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = StudentService.instance.fetchStudents(widget.teacherId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이름을 선택하세요')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
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
                    '등록된 학생이 없습니다.\n선생님 관리자 화면에서 학생을 먼저 등록해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return _StudentTile(
                    student: student,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentBooksScreen(
                          teacherId: widget.teacherId,
                          student: student,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const _StudentTile({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: accentPurple,
                child: Text(
                  student.name.isNotEmpty ? student.name.substring(0, 1) : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                student.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
