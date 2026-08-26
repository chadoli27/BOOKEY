import 'package:flutter/material.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/models/student.dart';
import 'package:bookey/services/book_read_service.dart';
import 'package:bookey/services/book_service.dart';
import 'package:bookey/services/student_service.dart';

class _Roster {
  final List<Student> students;
  final Map<String, int> starCounts;
  final int totalBooks;

  const _Roster({
    required this.students,
    required this.starCounts,
    required this.totalBooks,
  });
}

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
  late Future<_Roster> _rosterFuture;

  @override
  void initState() {
    super.initState();
    _rosterFuture = _loadRoster();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<_Roster> _loadRoster() async {
    final results = await Future.wait([
      _service.fetchStudents(widget.teacherId),
      BookService.instance.fetchBooks(widget.teacherId),
      BookReadService.instance.fetchReadsForTeacher(widget.teacherId),
    ]);
    final students = results[0] as List<Student>;
    final totalBooks = (results[1] as List).length;
    final reads = results[2] as List<BookReadEntry>;
    final counts = <String, int>{};
    for (final read in reads) {
      counts[read.studentId] = (counts[read.studentId] ?? 0) + 1;
    }
    return _Roster(
      students: students,
      starCounts: counts,
      totalBooks: totalBooks,
    );
  }

  void _reload() {
    setState(() {
      _rosterFuture = _loadRoster();
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
      builder: (context) => _DarkDialog(
        title: '학생 삭제',
        content: '${student.name} 학생을 삭제할까요?\n체크된 독서 기록도 함께 삭제됩니다.',
        confirmLabel: '삭제',
        destructive: true,
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
      backgroundColor: darkBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkBg, darkBgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<_Roster>(
                      future: _rosterFuture,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.students.length;
                        return Row(
                          children: [
                            _BackButton(
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              '학생 관리',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (count != null)
                              Text(
                                '$count명',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: textMuted,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: darkPanel,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: darkBorder),
                            ),
                            child: TextField(
                              controller: _nameController,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addStudent(),
                              style: const TextStyle(color: textLight),
                              cursorColor: gold,
                              decoration: const InputDecoration(
                                hintText: '학생 이름을 입력하세요',
                                hintStyle: TextStyle(color: textFaint),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _isAdding ? null : _addStudent,
                          style: FilledButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: const Color(0xFF241C0B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('등록'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: FutureBuilder<_Roster>(
                        future: _rosterFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '불러오기 실패: ${snapshot.error}',
                                style: const TextStyle(color: textMuted),
                              ),
                            );
                          }
                          final roster = snapshot.data;
                          if (roster == null) {
                            return const Center(
                              child: CircularProgressIndicator(color: gold),
                            );
                          }
                          if (roster.students.isEmpty) {
                            return const Center(
                              child: Text(
                                '등록된 학생이 없습니다.',
                                style: TextStyle(color: textMuted),
                              ),
                            );
                          }
                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 460,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 3.6,
                                ),
                            itemCount: roster.students.length,
                            itemBuilder: (context, index) {
                              final student = roster.students[index];
                              return _StudentCard(
                                student: student,
                                starCount:
                                    roster.starCounts[student.id] ?? 0,
                                totalBooks: roster.totalBooks,
                                onDelete: () => _confirmDelete(student),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: darkPanel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: darkBorder),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: textLight),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final int starCount;
  final int totalBooks;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.student,
    required this.starCount,
    required this.totalBooks,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalBooks == 0
        ? 0.0
        : (starCount / totalBooks).clamp(0.0, 1.0);
    final name = student.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: darkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: darkBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: gold,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1) : '?',
              style: const TextStyle(
                color: Color(0xFF241C0B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '별 $starCount개',
                      style: const TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7,
                    backgroundColor: darkBorder,
                    valueColor: const AlwaysStoppedAnimation(gold),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: textFaint),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _DarkDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final bool destructive;

  const _DarkDialog({
    required this.title,
    required this.content,
    required this.confirmLabel,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: darkPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: const TextStyle(color: textLight)),
      content: Text(content, style: const TextStyle(color: textMuted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: textMuted),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? Colors.redAccent : gold,
            foregroundColor: destructive ? Colors.white : const Color(0xFF241C0B),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
