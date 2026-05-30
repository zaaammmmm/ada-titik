// lib/core/services/notification_service.dart
//
// NotificationService – manajemen izin dan tampilan notifikasi lokal.
//
// Mendukung:
//   • Android: runtime permission (Android 13+) + local notifications via
//              flutter_local_notifications.
//   • Linux desktop: graceful fallback (print ke console, tidak crash).
//
// Catatan arsitektur:
//   Notifikasi dari backend (Supabase realtime / REST polling) ditangani oleh
//   NotificationRepository + SupabaseRealtimeService. Service ini bertanggung
//   jawab untuk:
//     1. Meminta izin notifikasi dari OS.
//     2. Menampilkan notifikasi lokal (badge, heads-up) ketika app menerima
//        event dari backend saat di foreground atau background.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Status izin notifikasi.
enum NotificationPermissionStatus {
  granted,
  denied,
  deniedForever,
  notSupported, // platform tidak mendukung (Linux desktop)
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Platform ────────────────────────────────────────────────────────────

  bool get _isLinuxDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  bool get _isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  // ─── Inisialisasi ────────────────────────────────────────────────────────

  /// Inisialisasi plugin. Panggil sekali saat startup (di main()).
  Future<void> initialize() async {
    if (_initialized) return;

    if (_isLinuxDesktop) {
      // flutter_local_notifications tidak support Linux → skip.
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // icon notifikasi
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // kita minta manual
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

    // Buat notification channel Android (wajib Android 8+).
    if (_isAndroid) {
      await _createAndroidChannels();
    }

    _initialized = true;
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Channel utama
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

    // Channel nearby (nearby donation points)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'ada_titik_nearby',
        'Titik Donasi Terdekat',
        description: 'Notifikasi titik donasi baru di sekitar Anda.',
        importance: Importance.defaultImportance,
        playSound: false,
      ),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Deep-link handling bisa ditambahkan di sini.
    // Contoh: parse payload -> navigate ke pointId.
  }

  // ─── Permission ──────────────────────────────────────────────────────────

  /// Cek dan minta izin notifikasi.
  ///
  /// Kembalikan [NotificationPermissionStatus] agar UI bisa tampilkan
  /// pesan yang tepat.
  Future<NotificationPermissionStatus> requestPermission() async {
    if (_isLinuxDesktop) {
      return NotificationPermissionStatus.notSupported;
    }

    if (_isAndroid) {
      return _requestAndroidPermission();
    }

    // iOS / macOS
    return _requestDarwinPermission();
  }

  Future<NotificationPermissionStatus> _requestAndroidPermission() async {
    // Android < 13: tidak perlu runtime permission untuk notifikasi.
    // Kita cek via permission_handler yang sudah menangani versi.
    final status = await Permission.notification.status;

    if (status.isGranted) return NotificationPermissionStatus.granted;
    if (status.isPermanentlyDenied) {
      return NotificationPermissionStatus.deniedForever;
    }

    final result = await Permission.notification.request();
    if (result.isGranted) return NotificationPermissionStatus.granted;
    if (result.isPermanentlyDenied) {
      return NotificationPermissionStatus.deniedForever;
    }
    return NotificationPermissionStatus.denied;
  }

  Future<NotificationPermissionStatus> _requestDarwinPermission() async {
    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin == null) return NotificationPermissionStatus.notSupported;

    final granted = await iosPlugin.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return (granted == true)
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  /// Cek apakah izin sudah diberikan (tanpa meminta).
  Future<bool> hasPermission() async {
    if (_isLinuxDesktop) return true; // di Linux kita print ke console
    if (_isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    // iOS: selalu coba tampilkan, OS yang handle.
    return true;
  }

  // ─── Show notifications ───────────────────────────────────────────────────

  /// Tampilkan notifikasi lokal.
  ///
  /// Digunakan ketika app menerima event dari backend (realtime / polling)
  /// saat app sedang foreground.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isNearby = false,
  }) async {
    if (_isLinuxDesktop) {
      // Fallback: print di console (tidak ada local notification di Linux Flutter)
      print('🔔 [$title] $body');
      return;
    }

    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      isNearby ? 'ada_titik_nearby' : 'ada_titik_main',
      isNearby ? 'Titik Donasi Terdekat' : 'Ada Titik! Notifikasi',
      channelDescription: isNearby
          ? 'Notifikasi titik donasi baru di sekitar Anda.'
          : 'Notifikasi donasi, komunitas, dan pembaruan titik.',
      importance: isNearby ? Importance.defaultImportance : Importance.high,
      priority: isNearby ? Priority.defaultPriority : Priority.high,
      styleInformation: BigTextStyleInformation(body),
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      print('⚠️ NotificationService.show error: $e');
    }
  }

  /// Notifikasi untuk titik donasi baru di sekitar user.
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

  /// Notifikasi untuk status donasi (departure, accepted, completed).
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
}
