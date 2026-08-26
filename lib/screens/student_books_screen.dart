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
          child: FutureBuilder<List<Book>>(
            future: _booksFuture,
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
              final books = snapshot.data!;
              final readCount = _readBookIds.length;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: _Header(
                      studentName: widget.student.name,
                      readCount: readCount,
                      totalCount: books.length,
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: books.isEmpty
                        ? const Center(
                            child: Text(
                              '등록된 책이 없습니다.',
                              style: TextStyle(color: textMuted),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 240,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 18,
                                  childAspectRatio: 0.72,
                                ),
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              final isRead = _readBookIds.contains(book.id);
                              final isPending = _pendingBookIds.contains(
                                book.id,
                              );
                              return _BookTile(
                                book: book,
                                isRead: isRead,
                                isPending: isPending,
                                onTap: () => _toggle(book),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String studentName;
  final int readCount;
  final int totalCount;
  final VoidCallback onBack;

  const _Header({
    required this.studentName,
    required this.readCount,
    required this.totalCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalCount == 0
        ? 0.0
        : (readCount / totalCount).clamp(0.0, 1.0);
    final nextMilestone = ((readCount ~/ 5) + 1) * 5;
    final remaining = nextMilestone - readCount;
    final showMilestone = totalCount > 0 && readCount < totalCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: darkPanel,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onBack,
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
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$studentName의 밤하늘',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '별 $readCount / $totalCount개',
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
        if (showMilestone) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: darkPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: darkBorder),
            ),
            child: Column(
              children: [
                Text(
                  '$remaining개',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: gold,
                  ),
                ),
                const Text(
                  '다음 별자리까지',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ],
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
      color: darkPanel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isPending ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isRead ? gold : darkBorder, width: isRead ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            book.coverUrl != null && book.coverUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: book.coverUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) =>
                                    const _CoverPlaceholder(),
                              )
                            : const _CoverPlaceholder(),
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
                            color: isRead ? gold : darkPanelAlt,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isRead ? gold : darkBorder,
                            ),
                          ),
                          child: Icon(
                            isRead ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isRead ? const Color(0xFF241C0B) : textFaint,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkPanelAlt,
      child: const Icon(Icons.menu_book_rounded, color: textFaint, size: 36),
    );
  }
}
