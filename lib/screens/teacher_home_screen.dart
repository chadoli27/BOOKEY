import 'package:flutter/material.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/screens/book_management_screen.dart';
import 'package:bookey/screens/reading_status_screen.dart';
import 'package:bookey/screens/student_management_screen.dart';
import 'package:bookey/screens/student_select_screen.dart';
import 'package:bookey/services/book_read_service.dart';
import 'package:bookey/services/book_service.dart';
import 'package:bookey/services/student_service.dart';

class _DashboardData {
  final int studentCount;
  final int bookCount;
  final int starsToday;
  final int completedThisWeek;
  final List<_ActivityItem> recentActivity;

  const _DashboardData({
    required this.studentCount,
    required this.bookCount,
    required this.starsToday,
    required this.completedThisWeek,
    required this.recentActivity,
  });
}

class _ActivityItem {
  final String studentName;
  final String bookTitle;
  final DateTime checkedAt;
  final bool isFirstStar;

  const _ActivityItem({
    required this.studentName,
    required this.bookTitle,
    required this.checkedAt,
    required this.isFirstStar,
  });
}

class TeacherHomeScreen extends StatefulWidget {
  final String teacherId;
  final String? teacherEmail;
  final VoidCallback onLogout;

  const TeacherHomeScreen({
    super.key,
    required this.teacherId,
    this.teacherEmail,
    required this.onLogout,
  });

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  void _reload() {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
  }

  Future<_DashboardData> _loadDashboard() async {
    final results = await Future.wait([
      StudentService.instance.fetchStudents(widget.teacherId),
      BookService.instance.fetchBooks(widget.teacherId),
      BookReadService.instance.fetchReadsForTeacher(widget.teacherId),
    ]);
    final studentCount = results[0].length;
    final bookCount = results[1].length;
    final reads = results[2] as List<BookReadEntry>;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    var starsToday = 0;
    var completedThisWeek = 0;
    final earliestByStudent = <String, DateTime>{};
    for (final read in reads) {
      final local = read.checkedAt.toLocal();
      if (!local.isBefore(today)) starsToday++;
      if (!local.isBefore(startOfWeek)) completedThisWeek++;
      final earliest = earliestByStudent[read.studentId];
      if (earliest == null || read.checkedAt.isBefore(earliest)) {
        earliestByStudent[read.studentId] = read.checkedAt;
      }
    }

    final recentActivity = reads
        .take(6)
        .map(
          (read) => _ActivityItem(
            studentName: read.studentName,
            bookTitle: read.bookTitle,
            checkedAt: read.checkedAt,
            isFirstStar: earliestByStudent[read.studentId] == read.checkedAt,
          ),
        )
        .toList();

    return _DashboardData(
      studentCount: studentCount,
      bookCount: bookCount,
      starsToday: starsToday,
      completedThisWeek: completedThisWeek,
      recentActivity: recentActivity,
    );
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      email: widget.teacherEmail,
                      onKiosk: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentSelectScreen(teacherId: widget.teacherId),
                        ),
                      ),
                      onLogout: widget.onLogout,
                    ),
                    const SizedBox(height: 28),
                    FutureBuilder<_DashboardData>(
                      future: _dashboardFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              '불러오기 실패: ${snapshot.error}',
                              style: const TextStyle(color: textMuted),
                            ),
                          );
                        }
                        final data = snapshot.data;
                        if (data == null) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: CircularProgressIndicator(color: gold),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatRow(data: data),
                            const SizedBox(height: 24),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 760;
                                final activity = _RecentActivityPanel(
                                  items: data.recentActivity,
                                );
                                final actions = _ActionColumn(
                                  teacherId: widget.teacherId,
                                  onReturn: _reload,
                                );
                                if (!isWide) {
                                  return Column(
                                    children: [
                                      activity,
                                      const SizedBox(height: 20),
                                      actions,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: activity),
                                    const SizedBox(width: 20),
                                    Expanded(flex: 2, child: actions),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
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

class _Header extends StatelessWidget {
  final String? email;
  final VoidCallback onKiosk;
  final VoidCallback onLogout;

  const _Header({
    required this.email,
    required this.onKiosk,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '북키 관리자',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: textLight,
                ),
              ),
              if (email != null) ...[
                const SizedBox(height: 4),
                Text(
                  email!,
                  style: const TextStyle(fontSize: 14, color: textMuted),
                ),
              ],
            ],
          ),
        ),
        FilledButton(
          onPressed: onKiosk,
          style: FilledButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: const Color(0xFF241C0B),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
          child: const Text('키오스크 모드 시작'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: onLogout,
          style: OutlinedButton.styleFrom(
            foregroundColor: textLight,
            side: const BorderSide(color: darkBorder),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: const Text('로그아웃'),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final _DashboardData data;

  const _StatRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 620;
        final tiles = [
          _StatTile(label: '등록 학생', value: '${data.studentCount}명'),
          _StatTile(label: '등록 도서', value: '${data.bookCount}권'),
          _StatTile(
            label: '오늘 켜진 별',
            value: '${data.starsToday}개',
            highlighted: true,
          ),
          _StatTile(label: '이번 주 완독', value: '${data.completedThisWeek}권'),
        ];
        if (!isWide) {
          return Column(
            children: [
              for (final t in tiles) ...[
                t,
                if (t != tiles.last) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (final t in tiles) ...[
              Expanded(child: t),
              if (t != tiles.last) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _StatTile({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: highlighted ? darkGoldPanel : darkPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? darkGoldBorder : darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: highlighted ? gold : textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityPanel extends StatelessWidget {
  final List<_ActivityItem> items;

  const _RecentActivityPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 활동',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textLight,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '아직 기록된 활동이 없습니다.',
                style: TextStyle(color: textMuted),
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _ActivityRow(item: items[i]),
              if (i != items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Divider(height: 1, color: darkBorder),
                ),
            ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;

  const _ActivityRow({required this.item});

  String _relativeTime(DateTime checkedAt) {
    final diff = DateTime.now().difference(checkedAt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final description = item.isFirstStar
        ? '첫 별을 모았어요'
        : '「${item.bookTitle}」 완독';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: darkGoldPanel,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: gold, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: textLight),
                children: [
                  TextSpan(
                    text: item.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: ' · $description',
                    style: const TextStyle(color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _relativeTime(item.checkedAt),
            style: const TextStyle(fontSize: 12, color: textFaint),
          ),
        ],
      ),
    );
  }
}

class _ActionColumn extends StatelessWidget {
  final String teacherId;
  final VoidCallback onReturn;

  const _ActionColumn({required this.teacherId, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionCard(
          icon: Icons.groups_rounded,
          iconColor: iconBoxPurple,
          title: '학생 관리',
          subtitle: '이름을 등록하고 삭제합니다',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentManagementScreen(teacherId: teacherId),
              ),
            );
            onReturn();
          },
        ),
        const SizedBox(height: 16),
        _ActionCard(
          icon: Icons.menu_book_rounded,
          iconColor: iconBoxTeal,
          title: '책 관리',
          subtitle: '책 목록과 표지를 관리합니다',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookManagementScreen(teacherId: teacherId),
              ),
            );
            onReturn();
          },
        ),
        const SizedBox(height: 16),
        _ActionCard(
          icon: Icons.bar_chart_rounded,
          iconColor: iconBoxOlive,
          title: '읽기 현황',
          subtitle: '학생별 진행률을 확인합니다',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReadingStatusScreen(teacherId: teacherId),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: darkPanel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: darkBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: textLight, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
