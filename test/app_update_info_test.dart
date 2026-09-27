import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/model/app_update_info.dart';

void main() {
  const apkUrl =
      'https://firebasestorage.googleapis.com/v0/b/clinic-86788.firebasestorage.app/o/clinic_updates%2Fclinic-system-v1.1.0.apk?alt=media&token=example';

  AppUpdateInfo parse(Map<String, String> values, {int installedBuild = 1}) =>
      AppUpdateInfo.fromValues(
        installedVersion: '1.0.0',
        installedBuild: installedBuild,
        values: values,
      );

  test('newer build is optional when force_update is false', () {
    final update = parse({
      'latest_version': '1.1.0',
      'latest_build': '2',
      'minimum_build': '1',
      'force_update': 'false',
      'apk_url': apkUrl,
      'release_notes': 'Bug fixes',
    });
    expect(update.kind, AppUpdateKind.optional);
    expect(update.latestVersion, '1.1.0');
    expect(update.apkUrl.toString(), apkUrl);
  });

  test('force flag or minimum build requires the update', () {
    expect(
      parse({'latest_build': '2', 'force_update': 'true'}).kind,
      AppUpdateKind.required,
    );
    expect(
      parse({'latest_build': '2', 'minimum_build': '2'}).kind,
      AppUpdateKind.required,
    );
  });

  test('current build and malformed optional config do not prompt', () {
    expect(parse({'latest_build': '1'}).kind, AppUpdateKind.none);
    expect(parse({'latest_build': 'invalid'}).kind, AppUpdateKind.none);
    expect(parse({}).kind, AppUpdateKind.none);
  });

  test('required update stays required with a missing or unsafe URL', () {
    final update = parse({
      'latest_build': '2',
      'minimum_build': '2',
      'apk_url': 'http://example.com/app.apk',
    });
    expect(update.kind, AppUpdateKind.required);
    expect(update.apkUrl, isNull);
  });
}
