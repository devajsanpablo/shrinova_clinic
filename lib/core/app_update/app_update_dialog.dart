import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/app_update_info.dart';
import '../theme.dart';
import 'app_update_service.dart';

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({super.key, required this.info, required this.service});

  final AppUpdateInfo info;
  final AppUpdateService service;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog>
    with WidgetsBindingObserver {
  late AppUpdateInfo _info = widget.info;
  bool _busy = false;
  bool _waitingForPermission = false;
  int _progress = 0;
  bool _waitingForNetwork = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForPermission) {
      _resumeInstallation();
    }
  }

  Future<void> _resumeInstallation() async {
    _waitingForPermission = false;
    try {
      if (await widget.service.canInstallPackages()) {
        await widget.service.installDownloadedApk();
      } else if (mounted) {
        setState(() {
          _error = 'Allow installs from this app in Android settings, then tap Update Now.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not open the Android installer. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateNow() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _progress = 0;
      _waitingForNetwork = false;
    });
    try {
      if (_info.apkUrl == null) {
        final refreshed = await widget.service.check();
        if (refreshed != null && mounted) setState(() => _info = refreshed);
        if (_info.apkUrl == null) {
          throw const FormatException(
            'No valid Firebase Storage APK URL is configured. Ask your administrator to publish one.',
          );
        }
      }
      await widget.service.startDownload(_info);
      while (mounted) {
        final status = await widget.service.downloadStatus();
        if (status.state == 'failed' || status.state == 'missing') {
          throw StateError(
            'The APK download failed. Check your connection and try again.',
          );
        }
        if (status.state == 'complete') break;
        setState(() {
          _progress = status.progress;
          _waitingForNetwork = status.state == 'paused';
        });
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (!mounted) return;
      final result = await widget.service.installDownloadedApk();
      if (result == 'settings') {
        _waitingForPermission = true;
        return;
      }
      if (result != 'launched') {
        throw StateError('Could not open the Android installer. Try again.');
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : error is StateError
              ? error.message
              : error is PlatformException
              ? error.message ?? 'Android could not install this APK.'
              : 'The update could not start. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted && !_waitingForPermission) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = _info.releaseNotes
        .split(RegExp(r'\r?\n|•'))
        .map((line) => line.trim().replaceFirst(RegExp(r'^[-*]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();

    return PopScope(
      canPop: !_info.required,
      child: AlertDialog(
        title: Text(_info.required ? 'Update Required' : 'Update Available'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _info.required
                      ? 'A newer version of the Clinic System is required to continue.'
                      : 'Version ${_info.latestVersion} is available.',
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    "What's New",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final note in notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $note'),
                    ),
                ],
                if (_busy) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _progress > 0 ? _progress / 100 : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _waitingForNetwork
                        ? 'Waiting for a network connection…'
                        : 'Downloading update${_progress > 0 ? ' ($_progress%)' : '…'}',
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (!_info.required)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          FilledButton(
            onPressed: _busy ? null : _updateNow,
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
