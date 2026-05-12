import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({required this.update, super.key});

  final UpdateInfo update;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();

  static Future<void> showIfAvailable(BuildContext context, UpdateService service) async {
    final result = await service.check();
    if (!context.mounted) return;
    if (result.hasUpdate) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDialog(update: result.update!),
      );
    }
  }
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  static const _channel = MethodChannel('com.szk333333.course_schedule_app/installer');

  Future<void> _downloadAndInstall() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final dir = await getExternalStorageDirectory();
      final file = File('${dir!.path}/app-update.apk');
      if (file.existsSync()) await file.delete();

      final uri = Uri.parse(widget.update.downloadUrl);
      final request = http.Request('GET', uri);
      final response = await http.Client().send(request);

      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (mounted && total > 0) {
          setState(() => _progress = received / total);
        }
      }
      await sink.close();

      if (mounted) {
        setState(() => _progress = 1.0);
        await Future.delayed(const Duration(milliseconds: 300));

        await _channel.invokeMethod('install', {'path': file.path});
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.code == 'INSTALL_PERMISSION_REQUIRED'
              ? '请在打开的系统设置中允许本应用安装未知应用，然后返回重新点击下载更新。'
              : '安装失败: ${e.message ?? e.code}';
          _downloading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '安装失败: $e');
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Color(0xFF0066FF)),
          const SizedBox(width: 10),
          Text('发现新版本 ${widget.update.versionName}'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.update.changelog.isNotEmpty && !_downloading) ...[
            const Text('更新内容：', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(widget.update.changelog),
          ],
          if (_downloading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            const SizedBox(height: 8),
            Text(_progress > 0 ? '下载中 ${(_progress * 100).toStringAsFixed(0)}%' : '正在连接...', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _downloading ? null : () => Navigator.of(context).pop(),
          child: const Text('稍后'),
        ),
        FilledButton.icon(
          icon: _downloading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download, size: 18),
          label: Text(_downloading ? '下载中' : '下载更新'),
          onPressed: _downloading ? null : _downloadAndInstall,
        ),
      ],
    );
  }
}
