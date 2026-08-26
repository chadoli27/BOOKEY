import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/models/book.dart';
import 'package:bookey/services/book_read_service.dart';
import 'package:bookey/services/book_service.dart';
import 'package:bookey/widgets/cover_drop_zone.dart';

enum _Filter { all, noCover }

class _Library {
  final List<Book> books;
  final Map<String, int> readCounts;

  const _Library({required this.books, required this.readCounts});
}

class BookManagementScreen extends StatefulWidget {
  final String teacherId;

  const BookManagementScreen({super.key, required this.teacherId});

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  final _service = BookService.instance;
  late Future<_Library> _libraryFuture;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _libraryFuture = _loadLibrary();
  }

  Future<_Library> _loadLibrary() async {
    final results = await Future.wait([
      _service.fetchBooks(widget.teacherId),
      BookReadService.instance.fetchReadsForTeacher(widget.teacherId),
    ]);
    final books = results[0] as List<Book>;
    final reads = results[1] as List<BookReadEntry>;
    final counts = <String, int>{};
    for (final read in reads) {
      counts[read.bookId] = (counts[read.bookId] ?? 0) + 1;
    }
    return _Library(books: books, readCounts: counts);
  }

  void _reload() {
    setState(() {
      _libraryFuture = _loadLibrary();
    });
  }

  Future<void> _showAddBookDialog() async {
    final titleController = TextEditingController();
    final coverUrlController = TextEditingController();

    final saved = await _showBookFormDialog(
      dialogTitle: '책 등록',
      confirmLabel: '등록',
      titleController: titleController,
      coverUrlController: coverUrlController,
    );

    if (saved != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;

    try {
      await _service.createBook(
        widget.teacherId,
        title,
        coverUrl: coverUrlController.text,
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('책 등록 실패: $e')));
    }
  }

  Future<void> _showEditBookDialog(Book book) async {
    final titleController = TextEditingController(text: book.title);
    final coverUrlController = TextEditingController(
      text: book.coverUrl ?? '',
    );

    final saved = await _showBookFormDialog(
      dialogTitle: '책 정보 수정',
      confirmLabel: '저장',
      titleController: titleController,
      coverUrlController: coverUrlController,
    );

    if (saved != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;

    try {
      await _service.updateBook(
        widget.teacherId,
        book.id,
        title,
        coverUrl: coverUrlController.text,
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('책 수정 실패: $e')));
    }
  }

  Future<bool?> _showBookFormDialog({
    required String dialogTitle,
    required String confirmLabel,
    required TextEditingController titleController,
    required TextEditingController coverUrlController,
  }) {
    InputDecoration decoration(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(dialogTitle, style: const TextStyle(color: textLight)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(color: textLight),
              cursorColor: gold,
              decoration: decoration('책 제목'),
            ),
            const SizedBox(height: 16),
            CoverDropZone(
              teacherId: widget.teacherId,
              controller: coverUrlController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: textMuted),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: const Color(0xFF241C0B),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('책 삭제', style: TextStyle(color: textLight)),
        content: Text(
          '"${book.title}"을(를) 삭제할까요?',
          style: const TextStyle(color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: textMuted),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteBook(widget.teacherId, book.id);
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
                    Row(
                      children: [
                        _BackButton(onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 16),
                        const Text(
                          '책 관리',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        FutureBuilder<_Library>(
                          future: _libraryFuture,
                          builder: (context, snapshot) {
                            final count = snapshot.data?.books.length;
                            if (count == null) return const SizedBox.shrink();
                            return Text(
                              '$count권',
                              style: const TextStyle(
                                fontSize: 15,
                                color: textMuted,
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _showAddBookDialog,
                          style: FilledButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: const Color(0xFF241C0B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('책 추가'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<_Library>(
                      future: _libraryFuture,
                      builder: (context, snapshot) {
                        final books = snapshot.data?.books ?? const [];
                        final noCoverCount = books
                            .where(
                              (b) =>
                                  b.coverUrl == null || b.coverUrl!.isEmpty,
                            )
                            .length;
                        return Wrap(
                          spacing: 10,
                          children: [
                            _FilterChip(
                              label: '전체 ${books.length}',
                              selected: _filter == _Filter.all,
                              onTap: () =>
                                  setState(() => _filter = _Filter.all),
                            ),
                            _FilterChip(
                              label: '표지 없음 $noCoverCount',
                              selected: _filter == _Filter.noCover,
                              onTap: () =>
                                  setState(() => _filter = _Filter.noCover),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<_Library>(
                        future: _libraryFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '불러오기 실패: ${snapshot.error}',
                                style: const TextStyle(color: textMuted),
                              ),
                            );
                          }
                          final library = snapshot.data;
                          if (library == null) {
                            return const Center(
                              child: CircularProgressIndicator(color: gold),
                            );
                          }
                          if (library.books.isEmpty) {
                            return const Center(
                              child: Text(
                                '등록된 책이 없습니다. 오른쪽 위 + 버튼으로 추가하세요.',
                                style: TextStyle(color: textMuted),
                              ),
                            );
                          }
                          final filtered = library.books.where((b) {
                            switch (_filter) {
                              case _Filter.all:
                                return true;
                              case _Filter.noCover:
                                return b.coverUrl == null ||
                                    b.coverUrl!.isEmpty;
                            }
                          }).toList();
                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text(
                                '해당하는 책이 없습니다.',
                                style: TextStyle(color: textMuted),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final book = filtered[index];
                              return _BookRow(
                                book: book,
                                readCount:
                                    library.readCounts[book.id] ?? 0,
                                onEdit: () => _showEditBookDialog(book),
                                onDelete: () => _confirmDelete(book),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? gold : darkPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? gold : darkBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF241C0B) : textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  final Book book;
  final int readCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookRow({
    required this.book,
    required this.readCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: darkPanel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: darkBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 56,
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _CoverPlaceholder(),
                        ),
                      )
                    : _CoverPlaceholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  book.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textLight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: darkBorder),
                  color: darkPanelAlt,
                ),
                child: Text(
                  '읽음 $readCount명',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: textFaint),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: textFaint,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkPanelAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: darkBorder),
      ),
      child: const Icon(Icons.menu_book_rounded, color: textFaint, size: 20),
    );
  }
}
