enum AppUpdateKind { none, optional, required }

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.installedVersion,
    required this.installedBuild,
    required this.latestVersion,
    required this.latestBuild,
    required this.minimumBuild,
    required this.kind,
    required this.releaseNotes,
    required this.apkUrl,
  });

  final String installedVersion;
  final int installedBuild;
  final String latestVersion;
  final int latestBuild;
  final int minimumBuild;
  final AppUpdateKind kind;
  final String releaseNotes;
  final Uri? apkUrl;

  bool get required => kind == AppUpdateKind.required;
  bool get available => kind != AppUpdateKind.none;

  static AppUpdateInfo fromValues({
    required String installedVersion,
    required int installedBuild,
    required Map<String, String> values,
  }) {
    final latestBuild =
        int.tryParse(values['latest_build']?.trim() ?? '') ?? installedBuild;
    final minimumBuild =
        int.tryParse(values['minimum_build']?.trim() ?? '') ?? 1;
    final forceUpdate = values['force_update']?.trim().toLowerCase() == 'true';
    final newer = latestBuild > installedBuild;
    final required = installedBuild < minimumBuild || (newer && forceUpdate);
    final rawUrl = Uri.tryParse(values['apk_url']?.trim() ?? '');
    final apkUrl =
        rawUrl?.scheme == 'https' &&
            rawUrl?.host == 'firebasestorage.googleapis.com'
        ? rawUrl
        : null;

    return AppUpdateInfo(
      installedVersion: installedVersion,
      installedBuild: installedBuild,
      latestVersion: values['latest_version']?.trim().isNotEmpty == true
          ? values['latest_version']!.trim()
          : installedVersion,
      latestBuild: latestBuild,
      minimumBuild: minimumBuild,
      kind: required
          ? AppUpdateKind.required
          : newer
          ? AppUpdateKind.optional
          : AppUpdateKind.none,
      releaseNotes: values['release_notes']?.trim() ?? '',
      apkUrl: apkUrl,
    );
  }
}
