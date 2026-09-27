import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClinicNotifications extends ChangeNotifier {
  ClinicNotifications._();
  static final instance = ClinicNotifications._();
  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _messages, _opened;
  String? _uid, _token;
  VoidCallback? onOpen;
  bool enabled = false;
  String? error;
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> start(String uid, VoidCallback open) async {
    _uid = uid;
    onOpen = open;
    if (!supported) return;
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool('push_disabled_$uid') == true) return;
    await enable();
  }

  Future<void> enable() async {
    if (!supported || _uid == null) return;
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (_) => onOpen?.call(),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!
          .createNotificationChannel(
            const AndroidNotificationChannel(
              'consultation_tickets',
              'Consultation tickets',
              description: 'New tickets assigned to you',
              importance: Importance.high,
            ),
          );
      final permission = await FirebaseMessaging.instance.requestPermission();
      if (permission.authorizationStatus != AuthorizationStatus.authorized) {
        enabled = false;
        error = 'Notifications are blocked. Allow notifications in your device settings.';
        notifyListeners();
        return;
      }
      await _tokens?.cancel();
      await _messages?.cancel();
      await _opened?.cancel();
      _tokens = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        try {
          await _saveToken(token);
        } catch (_) {
          error = 'Unable to register this device. Try enabling notifications again.';
          notifyListeners();
        }
      });
      _messages = FirebaseMessaging.onMessage.listen((message) async {
        if (message.data['doctorUid'] != _uid || !enabled) return;
        await _local.show(
          id:
              (message.data['ticketId'] ?? message.messageId ?? '').hashCode &
              0x7fffffff,
          title: message.notification?.title,
          body: message.notification?.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'consultation_tickets',
              'Consultation tickets',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      });
      _opened = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (message.data['doctorUid'] == _uid) onOpen?.call();
      });
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) throw StateError('Device token unavailable');
      await _saveToken(token);
      enabled = true;
      await (await SharedPreferences.getInstance()).setBool(
        'push_disabled_$_uid',
        false,
      );
      error = null;
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      final launch = await _local.getNotificationAppLaunchDetails();
      if (initial?.data['doctorUid'] == _uid ||
          launch?.didNotificationLaunchApp == true) {
        onOpen?.call();
      }
    } catch (_) {
      enabled = false;
      error = 'Unable to enable push notifications. Check your connection and retry.';
    }
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final uid = _uid;
    if (uid == null || FirebaseAuth.instance.currentUser?.uid != uid) return;
    final devices = FirebaseFirestore.instance
        .collection('doctor')
        .doc(uid)
        .collection('devices');
    await devices.doc(token).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (_token != null && _token != token) await devices.doc(_token).delete();
    _token = token;
  }

  Future<void> disable({bool remember = true}) async {
    await _tokens?.cancel();
    if (_uid != null && _token != null) {
      await FirebaseFirestore.instance
          .collection('doctor')
          .doc(_uid)
          .collection('devices')
          .doc(_token)
          .delete();
    }
    if (supported) {
      await FirebaseMessaging.instance.deleteToken();
      await _local.cancelAll();
    }
    _token = null;
    if (remember && _uid != null) {
      await (await SharedPreferences.getInstance()).setBool(
        'push_disabled_$_uid',
        true,
      );
    }
    enabled = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_uid == null) return;
    await disable(remember: false);
    await detach();
    _uid = null;
  }

  Future<void> detach() async {
    onOpen = null;
    await _tokens?.cancel();
    await _messages?.cancel();
    await _opened?.cancel();
  }
}
