import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class MaintenanceController extends ChangeNotifier {
  bool ready = false, enabled = false, checking = false;
  String message =
      'The clinic system is undergoing maintenance. Please try again later.';
  String? error;
  FirebaseRemoteConfig? _config;
  StreamSubscription<RemoteConfigUpdate>? _subscription;
  Timer? _timer;
  bool _disposed = false;

  Future<void> refresh() async {
    if (checking || _disposed) return;
    checking = true;
    notifyListeners();
    try {
      if (_config == null) {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: kIsWeb
                ? const FirebaseOptions(
                    apiKey: 'AIzaSyAjrNDb1NHee9wXuRZMBD0c3aAm4Uj3O0Y',
                    appId: '1:713254298828:web:43696b6a3d659f33788e69',
                    messagingSenderId: '713254298828',
                    projectId: 'clinic-86788',
                    authDomain: 'clinic-86788.firebaseapp.com',
                  )
                : null,
          );
        }
        final config = FirebaseRemoteConfig.instance;
        await config.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 15),
            minimumFetchInterval: const Duration(minutes: 1),
          ),
        );
        await config.ensureInitialized();
        if (_disposed) return;
        _config = config;
        // Use the last activated state offline; don't invent an "open" state.
        _read();
        _subscription = config.onConfigUpdated.listen(
          (event) async {
            try {
              await config.activate();
              if (!_disposed) {
                _read();
                notifyListeners();
              }
            } catch (_) {
              /* Keep the last known state until the next fetch. */
            }
          },
          onError: (Object _) {
            /* Periodic fetch remains available. */
          },
        );
        _timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
      }
      await _config!.fetchAndActivate();
      if (!_disposed) {
        _read();
        if (!ready) {
          throw const FormatException('Missing maintenance configuration');
        }
        error = null;
      }
    } catch (_) {
      if (!_disposed) error = 'Unable to check system availability. Check your connection and retry.';
    } finally {
      if (!_disposed) {
        checking = false;
        notifyListeners();
      }
    }
  }

  void _read() {
    final raw = _config!.getString('clinic_maintenance');
    if (raw.isEmpty) return;
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['enabled'] is! bool ||
        data['message'] is! String ||
        data['target'] != 'both') {
      throw const FormatException('Invalid maintenance configuration');
    }
    enabled = data['enabled'] as bool;
    message = data['message'] as String;
    ready = true;
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
