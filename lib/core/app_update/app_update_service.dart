import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../model/app_update_info.dart';

class AppUpdateService {
  static const _channel = MethodChannel('clinic/app_updates');

  Future<AppUpdateInfo?> check() async {
    try {
      final package = await PackageInfo.fromPlatform();
      final installedBuild = int.tryParse(package.buildNumber);
      if (installedBuild == null) return null;

      final config = FirebaseRemoteConfig.instance;
      await config.setDefaults({
        'latest_version': package.version,
        'latest_build': installedBuild,
        'minimum_build': 1,
        'force_update': false,
        'apk_url': '',
        'release_notes': '',
      });
      try {
        await config.fetchAndActivate().timeout(const Duration(seconds: 8));
      } catch (_) {
        // Use the last activated values, or the defaults on first launch.
      }
      return AppUpdateInfo.fromValues(
        installedVersion: package.version,
        installedBuild: installedBuild,
        values: {
          for (final key in [
            'latest_version',
            'latest_build',
            'minimum_build',
            'force_update',
            'apk_url',
            'release_notes',
          ])
            key: config.getString(key),
        },
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> startDownload(AppUpdateInfo update) async {
    final url = update.apkUrl;
    if (url == null) {
      throw const FormatException('No valid APK URL is configured.');
    }
    await _channel.invokeMethod<void>('startDownload', {
      'url': url.toString(),
      'build': update.latestBuild,
    });
  }

  Future<({String state, int progress})> downloadStatus() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'downloadStatus',
    );
    return (
      state: result?['state'] as String? ?? 'missing',
      progress: result?['progress'] as int? ?? 0,
    );
  }

  Future<bool> canInstallPackages() async =>
      await _channel.invokeMethod<bool>('canInstallPackages') ?? false;

  /// Returns `settings` when Android needs the user to allow this app to
  /// install APKs, or `launched` after the system installer opens.
  Future<String> installDownloadedApk() async =>
      await _channel.invokeMethod<String>('installDownloadedApk') ?? 'failed';
}
