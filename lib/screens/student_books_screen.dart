import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/models/book.dart';
import 'package:bookey/models/student.dart';
import 'package:bookey/services/book_read_service.dart';
import 'package:bookey/services/book_service.dart';

class StudentBooksScreen extends StatefulWidget {
  final String teacherId;
  final Student student;

  const StudentBooksScreen({
    super.key,
    required this.teacherId,
    required this.student,
  });

  @override
  State<StudentBooksScreen> createState() => _StudentBooksScreenState();
}

class _StudentBooksScreenState extends State<StudentBooksScreen> {
  final _bookReadService = BookReadService.instance;
  late Future<List<Book>> _booksFuture;
  Set<String> _readBookIds = {};
  final Set<String> _pendingBookIds = {};

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadBooks();
  }

  Future<List<Book>> _loadBooks() async {
    final results = await Future.wait([
      BookService.instance.fetchBooks(widget.teacherId),
      _bookReadService.fetchReadBookIds(widget.student.id),
    ]);
    final books = results[0] as List<Book>;
    final readIds = results[1] as Set<String>;
    if (mounted) setState(() => _readBookIds = readIds);
    return books;
  }

  Future<void> _toggle(Book book) async {
    if (_pendingBookIds.contains(book.id)) return;

    final wasRead = _readBookIds.contains(book.id);
    setState(() {
      _pendingBookIds.add(book.id);
      if (wasRead) {
        _readBookIds.remove(book.id);
      } else {
        _readBookIds.add(book.id);
      }
    });

    try {
      if (wasRead) {
        await _bookReadService.markUnread(
          studentId: widget.student.id,
          bookId: book.id,
        );
      } else {
        await _bookReadService.markRead(
          teacherId: widget.teacherId,
          studentId: widget.student.id,
          bookId: book.id,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // roll back the optimistic update
        if (wasRead) {
          _readBookIds.add(book.id);
        } else {
          _readBookIds.remove(book.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장에 실패했어요. 다시 시도해주세요. ($e)')),
      );
    } finally {
      if (mounted) {
        setState(() => _pendingBookIds.remove(book.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.student.name}의 책 목록')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Book>>(
            future: _booksFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('불러오기 실패: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final books = snapshot.data!;
              if (books.isEmpty) {
                return Center(
                  child: Text(
                    '등록된 책이 없습니다.',
                    style: TextStyle(color: ink.withValues(alpha: 0.5)),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.78,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final isRead = _readBookIds.contains(book.id);
                  final isPending = _pendingBookIds.contains(book.id);
                  return _BookTile(
                    book: book,
                    isRead: isRead,
                    isPending: isPending,
                    onTap: () => _toggle(book),
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

class _BookTile extends StatelessWidget {
  final Book book;
  final bool isRead;
  final bool isPending;
  final VoidCallback onTap;

  const _BookTile({
    required this.book,
    required this.isRead,
    required this.isPending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isRead
          ? accentGreen.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isPending ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: book.coverUrl != null &&
                                book.coverUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: book.coverUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Container(
                                  color: tile,
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    color: ink,
                                    size: 40,
                                  ),
                                ),
                              )
                            : Container(
                                color: tile,
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: ink,
                                  size: 40,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: AnimatedOpacity(
                        opacity: isPending ? 0.4 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isRead ? Colors.green : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isRead
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            color: isRead ? Colors.white : ink,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                book.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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
