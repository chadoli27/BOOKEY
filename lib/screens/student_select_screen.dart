import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/models/student.dart';
import 'package:bookey/screens/student_books_screen.dart';
import 'package:bookey/services/kiosk_service.dart';
import 'package:bookey/services/student_service.dart';

/// 학생용 키오스크 화면 진입점. 로그인된 선생님 계정 위에서 학생 이름만
/// 골라 들어가는 화면 — 별도 인증 없음 (PRD 5.2). 단, 이 화면을 벗어나
/// 관리자 화면으로 돌아가려면 선생님 비밀번호 확인이 필요하다 — 학생이
/// 뒤로가기만으로 관리자 화면(학생/책 관리)에 들어가지 못하게 막기 위함.
class StudentSelectScreen extends StatefulWidget {
  final String teacherId;

  const StudentSelectScreen({super.key, required this.teacherId});

  @override
  State<StudentSelectScreen> createState() => _StudentSelectScreenState();
}

class _StudentSelectScreenState extends State<StudentSelectScreen> {
  late Future<List<Student>> _studentsFuture;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _studentsFuture = StudentService.instance.fetchStudents(widget.teacherId);
    unawaited(KioskService.instance.enable());
  }

  Future<void> _confirmExit() async {
    if (_isExiting) return;
    _isExiting = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _KioskExitDialog(),
      );
      if (confirmed != true) return;
      await KioskService.instance.disable();
      if (mounted) Navigator.of(context).pop();
    } finally {
      _isExiting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmExit());
      },
      child: Scaffold(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      Material(
                        color: darkPanel,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => unawaited(_confirmExit()),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: darkBorder),
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              color: textLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '이름을 선택하세요',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Student>>(
                    future: _studentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            '불러오기 실패: ${snapshot.error}',
                            style: const TextStyle(color: textMuted),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: gold),
                        );
                      }
                      final students = snapshot.data!;
                      if (students.isEmpty) {
                        return const Center(
                          child: Text(
                            '등록된 학생이 없습니다.\n선생님 관리자 화면에서 학생을 먼저 등록해주세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KioskExitDialog extends StatefulWidget {
  const _KioskExitDialog();

  @override
  State<_KioskExitDialog> createState() => _KioskExitDialogState();
}

class _KioskExitDialogState extends State<_KioskExitDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final password = _passwordController.text;
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (password.isEmpty || email == null) {
      setState(() => _error = '비밀번호를 입력해주세요.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '비밀번호가 올바르지 않습니다.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '확인하지 못했습니다: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: darkPanel,
      title: const Text('키오스크 모드 종료', style: TextStyle(color: textLight)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '선생님 비밀번호를 입력하면 관리자 화면으로 돌아갑니다.',
            style: TextStyle(color: textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            enabled: !_isLoading,
            style: const TextStyle(color: textLight),
            cursorColor: gold,
            onSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              labelText: '비밀번호',
              labelStyle: const TextStyle(color: textMuted),
              errorText: _error,
              filled: true,
              fillColor: darkPanelAlt,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: gold),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _verify,
          style: FilledButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: const Color(0xFF241C0B),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF241C0B),
                  ),
                )
              : const Text('확인'),
        ),
      ],
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
      color: darkPanel,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: darkBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: gold,
                child: Text(
                  student.name.isNotEmpty ? student.name.substring(0, 1) : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF241C0B),
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
                  color: textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
