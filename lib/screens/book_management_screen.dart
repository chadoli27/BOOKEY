import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/models/book.dart';
import 'package:bookey/services/book_service.dart';

class BookManagementScreen extends StatefulWidget {
  final String teacherId;

  const BookManagementScreen({super.key, required this.teacherId});

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  final _service = BookService.instance;
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _service.fetchBooks(widget.teacherId);
  }

  void _reload() {
    setState(() {
      _booksFuture = _service.fetchBooks(widget.teacherId);
    });
  }

  Future<void> _showAddBookDialog() async {
    final titleController = TextEditingController();
    final coverUrlController = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('책 등록'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '책 제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: coverUrlController,
              decoration: const InputDecoration(
                labelText: '표지 이미지 URL (선택)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('등록'),
          ),
        ],
      ),
    );

    if (added != true) return;
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

  Future<void> _confirmDelete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('책 삭제'),
        content: Text('"${book.title}"을(를) 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: const Text('책 관리'),
        actions: [
          IconButton(
            tooltip: '책 등록',
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddBookDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<Book>>(
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
                '등록된 책이 없습니다. 오른쪽 위 + 버튼으로 추가하세요.',
                style: TextStyle(color: ink.withValues(alpha: 0.5)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: SizedBox(
                  width: 44,
                  height: 60,
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const Icon(
                              Icons.menu_book_rounded,
                              color: ink,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: accentGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: ink),
                        ),
                ),
                title: Text(book.title),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _confirmDelete(book),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
