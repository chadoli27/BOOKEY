import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookey/screens/teacher_home_screen.dart';
import 'package:bookey/screens/teacher_login_screen.dart';
import 'package:bookey/services/teacher_service.dart';

class BookeyShell extends StatefulWidget {
  const BookeyShell({super.key});

  @override
  State<BookeyShell> createState() => _BookeyShellState();
}

class _BookeyShellState extends State<BookeyShell> {
  User? _pendingUser;
  String? _teacherId;
  String? _teacherEmail;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _onLoggedIn(user);
    }
  }

  Future<void> _onLoggedIn(User user) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _pendingUser = user;
    });
    try {
      // teachers 행이 실제로 만들어진 걸 확인한 뒤에만 홈 화면으로 넘어간다 —
      // 그래야 students/books의 teacher_id FK가 항상 유효한 행을 가리킨다.
      await TeacherService.instance.ensureTeacher(user.id);
      if (!mounted) return;
      setState(() {
        _teacherId = user.id;
        _teacherEmail = user.email;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '선생님 정보를 불러오지 못했습니다: $e';
      });
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    setState(() {
      _pendingUser = null;
      _teacherId = null;
      _teacherEmail = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = _teacherId;
    if (teacherId == null) {
      if (_isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (_error != null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final user = _pendingUser;
                      if (user != null) {
                        unawaited(_onLoggedIn(user));
                      } else {
                        setState(() => _error = null);
                      }
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return TeacherLoginScreen(onLoggedIn: (user) => unawaited(_onLoggedIn(user)));
    }
    return TeacherHomeScreen(
      teacherId: teacherId,
      teacherEmail: _teacherEmail,
      onLogout: () => unawaited(_logout()),
    );
  }
}
