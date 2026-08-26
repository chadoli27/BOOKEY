import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:bookey/constants.dart';
import 'package:bookey/services/book_service.dart';

const _allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

/// 표지 이미지를 드래그앤드랍(또는 클릭)으로 선택하면 즉시 Supabase Storage에
/// 업로드하고, 업로드된 공개 URL을 [controller]에 반영하는 입력 위젯.
class CoverDropZone extends StatefulWidget {
  final String teacherId;
  final TextEditingController controller;

  const CoverDropZone({
    super.key,
    required this.teacherId,
    required this.controller,
  });

  @override
  State<CoverDropZone> createState() => _CoverDropZoneState();
}

class _CoverDropZoneState extends State<CoverDropZone> {
  bool _dragging = false;
  bool _uploading = false;
  String? _error;

  Future<void> _handleBytes(Uint8List bytes, String fileName) async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await BookService.instance.uploadCoverImage(
        widget.teacherId,
        bytes,
        fileName,
      );
      if (!mounted) return;
      setState(() => widget.controller.text = url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '업로드 실패: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    if (details.files.isEmpty) return;
    final file = details.files.first;
    final ext = _extensionOf(file.name);
    if (!_allowedExtensions.contains(ext)) {
      setState(() => _error = '이미지 파일만 지원해요 (jpg, png, gif, webp)');
      return;
    }
    final bytes = await file.readAsBytes();
    await _handleBytes(bytes, file.name);
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;
    final picked = files.first;
    final bytes = await picked.readAsBytes();
    await _handleBytes(bytes, picked.name);
  }

  String _extensionOf(String name) {
    return name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
        : '';
  }

  void _clear() {
    setState(() {
      widget.controller.text = '';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '표지 이미지',
          style: TextStyle(color: textMuted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        DropTarget(
          onDragDone: _handleDrop,
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          child: Material(
            color: _dragging ? darkGoldPanel : darkPanelAlt,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _uploading ? null : _pickFile,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _dragging ? gold : darkBorder,
                    width: _dragging ? 2 : 1,
                  ),
                ),
                child: _buildContent(),
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    if (_uploading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: gold, strokeWidth: 2.4),
        ),
      );
    }

    final url = widget.controller.text.trim();
    if (url.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined, color: textFaint),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _clear,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_upload_outlined, color: textFaint, size: 28),
          SizedBox(height: 6),
          Text(
            '이미지를 드래그하거나 클릭해서 선택',
            style: TextStyle(color: textFaint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
