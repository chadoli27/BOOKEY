import 'package:flutter/material.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/screens/book_management_screen.dart';
import 'package:bookey/screens/student_management_screen.dart';
import 'package:bookey/screens/student_select_screen.dart';

class TeacherHomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookey · 관리자'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout_rounded),
            onPressed: onLogout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (teacherEmail != null) ...[
                      Text(
                        teacherEmail!,
                        style: TextStyle(
                          color: ink.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _HomeCard(
                      icon: Icons.groups_rounded,
                      title: '학생 관리',
                      subtitle: '학생 이름을 등록하고 삭제합니다',
                      color: accentPurple,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentManagementScreen(teacherId: teacherId),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _HomeCard(
                      icon: Icons.menu_book_rounded,
                      title: '책 관리',
                      subtitle: '책 목록을 등록하고 삭제합니다',
                      color: accentGreen,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BookManagementScreen(teacherId: teacherId),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _HomeCard(
                      icon: Icons.tablet_mac_rounded,
                      title: '키오스크 모드 진입',
                      subtitle: '학생 선택 화면으로 전환합니다',
                      color: accentYellow,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentSelectScreen(teacherId: teacherId),
                        ),
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

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: ink, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: ink.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ink.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
