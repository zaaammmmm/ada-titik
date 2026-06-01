// lib/core/services/notification_service.dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

enum NotificationPermissionStatus {
  granted,
  denied,
  deniedForever,
  notSupported,
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get _isLinuxDesktop {
    if (kIsWeb) return false;
    try { return Platform.isLinux; } catch (_) { return false; }
  }

  bool get _isAndroid {
    if (kIsWeb) return false;
    try { return Platform.isAndroid; } catch (_) { return false; }
  }

  bool get _isIOS {
    if (kIsWeb) return false;
    try { return Platform.isIOS; } catch (_) { return false; }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (_isLinuxDesktop) { _initialized = true; return; }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (_isAndroid) await _createAndroidChannels();
    _initialized = true;
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'ada_titik_main',
        'Ada Titik! Notifikasi',
        description: 'Notifikasi donasi, komunitas, dan pembaruan titik.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'ada_titik_nearby',
        'Titik Donasi Terdekat',
        description: 'Notifikasi titik donasi baru di sekitar Anda.',
        importance: Importance.defaultImportance,
        playSound: false,
      ),
    );

    // Channel untuk chat (agar notif pesan masuk saat background)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'ada_titik_chat',
        'Pesan Ada Titik!',
        description: 'Notifikasi pesan masuk dari pengguna lain.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Deep-link handling: parse payload -> navigate ke screen yang sesuai.
    // Contoh: 'point:xxx', 'chat:xxx', 'notification:xxx'
  }

  // ─── Permission ──────────────────────────────────────────────────────────

  Future<NotificationPermissionStatus> requestPermission() async {
    if (_isLinuxDesktop) return NotificationPermissionStatus.notSupported;
    if (_isAndroid) return _requestAndroidPermission();
    return _requestDarwinPermission();
  }

  Future<NotificationPermissionStatus> _requestAndroidPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return NotificationPermissionStatus.granted;
    if (status.isPermanentlyDenied) return NotificationPermissionStatus.deniedForever;

    final result = await Permission.notification.request();
    if (result.isGranted) return NotificationPermissionStatus.granted;
    if (result.isPermanentlyDenied) return NotificationPermissionStatus.deniedForever;
    return NotificationPermissionStatus.denied;
  }

  Future<NotificationPermissionStatus> _requestDarwinPermission() async {
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin == null) return NotificationPermissionStatus.notSupported;
    final granted = await iosPlugin.requestPermissions(
      alert: true, badge: true, sound: true,
    );
    return (granted == true)
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  Future<bool> hasPermission() async {
    if (_isLinuxDesktop) return true;
    if (_isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true;
  }

  /// Buka pengaturan notifikasi sistem perangkat secara langsung.
  /// Pada Android ini akan membuka halaman notifikasi khusus app di Setelan.
  /// Pada iOS ini akan membuka halaman Pengaturan app.
  Future<void> openSystemNotificationSettings() async {
    if (_isLinuxDesktop) return;
    // openAppSettings() dari permission_handler membuka langsung ke halaman
    // setelan app di Android maupun iOS — termasuk izin notifikasi background.
    await openAppSettings();
  }

  // ─── Show notifications ───────────────────────────────────────────────────

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isNearby = false,
    bool isChat = false,
  }) async {
    if (_isLinuxDesktop) {
      print('🔔 [$title] $body');
      return;
    }
    if (!_initialized) await initialize();

    String channelId;
    String channelName;
    String channelDesc;
    Importance importance;
    Priority priority;

    if (isChat) {
      channelId = 'ada_titik_chat';
      channelName = 'Pesan Ada Titik!';
      channelDesc = 'Notifikasi pesan masuk dari pengguna lain.';
      importance = Importance.high;
      priority = Priority.high;
    } else if (isNearby) {
      channelId = 'ada_titik_nearby';
      channelName = 'Titik Donasi Terdekat';
      channelDesc = 'Notifikasi titik donasi baru di sekitar Anda.';
      importance = Importance.defaultImportance;
      priority = Priority.defaultPriority;
    } else {
      channelId = 'ada_titik_main';
      channelName = 'Ada Titik! Notifikasi';
      channelDesc = 'Notifikasi donasi, komunitas, dan pembaruan titik.';
      importance = Importance.high;
      priority = Priority.high;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId, channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: priority,
      styleInformation: BigTextStyleInformation(body),
      icon: '@mipmap/ic_launcher',
      // Pastikan notifikasi tetap tampil bahkan saat background/terminated
      autoCancel: true,
      enableLights: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    try {
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      print('⚠️ NotificationService.show error: $e');
    }
  }

  Future<void> showNearbyDonation({
    required String pointId,
    required String title,
    required String location,
    required double distanceKm,
  }) async {
    await show(
      id: pointId.hashCode.abs() % 100000,
      title: '📍 Titik bantuan baru di dekatmu!',
      body: '$title – ${distanceKm.toStringAsFixed(1)} km dari lokasi Anda',
      payload: 'point:$pointId',
      isNearby: true,
    );
  }

  Future<void> showDonationUpdate({
    required String pointId,
    required String title,
    required String message,
  }) async {
    await show(
      id: ('donation_$pointId').hashCode.abs() % 100000,
      title: title,
      body: message,
      payload: 'point:$pointId',
    );
  }

  Future<void> showChatMessage({
    required String conversationId,
    required String senderName,
    required String message,
  }) async {
    await show(
      id: ('chat_$conversationId').hashCode.abs() % 100000,
      title: senderName,
      body: message,
      payload: 'chat:$conversationId',
      isChat: true,
    );
  }
}
