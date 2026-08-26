import 'package:flutter/material.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/models/student.dart';
import 'package:bookey/services/book_read_service.dart';
import 'package:bookey/services/book_service.dart';
import 'package:bookey/services/student_service.dart';

class _StudentProgress {
  final Student student;
  final int starCount;

  const _StudentProgress({required this.student, required this.starCount});
}

class ReadingStatusScreen extends StatefulWidget {
  final String teacherId;

  const ReadingStatusScreen({super.key, required this.teacherId});

  @override
  State<ReadingStatusScreen> createState() => _ReadingStatusScreenState();
}

class _ReadingStatusScreenState extends State<ReadingStatusScreen> {
  late Future<(List<_StudentProgress>, int)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<_StudentProgress>, int)> _load() async {
    final results = await Future.wait([
      StudentService.instance.fetchStudents(widget.teacherId),
      BookService.instance.fetchBooks(widget.teacherId),
      BookReadService.instance.fetchReadsForTeacher(widget.teacherId),
    ]);
    final students = results[0] as List<Student>;
    final bookCount = (results[1] as List).length;
    final reads = results[2] as List<BookReadEntry>;

    final counts = <String, int>{};
    for (final read in reads) {
      counts[read.studentId] = (counts[read.studentId] ?? 0) + 1;
    }

    final progress = students
        .map(
          (s) =>
              _StudentProgress(student: s, starCount: counts[s.id] ?? 0),
        )
        .toList()
      ..sort((a, b) => b.starCount.compareTo(a.starCount));

    return (progress, bookCount);
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
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _BackButton(onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 16),
                        const Text(
                          '읽기 현황',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: FutureBuilder<(List<_StudentProgress>, int)>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '불러오기 실패: ${snapshot.error}',
                                style: const TextStyle(color: textMuted),
                              ),
                            );
                          }
                          final data = snapshot.data;
                          if (data == null) {
                            return const Center(
                              child: CircularProgressIndicator(color: gold),
                            );
                          }
                          final (progress, bookCount) = data;
                          if (progress.isEmpty) {
                            return const Center(
                              child: Text(
                                '등록된 학생이 없습니다.',
                                style: TextStyle(color: textMuted),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: progress.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final p = progress[index];
                              return _ProgressRow(
                                progress: p,
                                total: bookCount,
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

class _ProgressRow extends StatelessWidget {
  final _StudentProgress progress;
  final int total;

  const _ProgressRow({required this.progress, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0
        ? 0.0
        : (progress.starCount / total).clamp(0.0, 1.0);
    final name = progress.student.name;
    return Container(
      padding: const EdgeInsets.all(18),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '별 ${progress.starCount}개',
                      style: const TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: darkBorder,
                    valueColor: const AlwaysStoppedAnimation(gold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
