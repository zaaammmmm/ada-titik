// lib/core/services/permission_service.dart
//
// PermissionService – helper terpusat untuk meminta semua izin app sekaligus.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  bool get _isLinux {
    if (kIsWeb) return false;
    try { return Platform.isLinux; } catch (_) { return false; }
  }

  bool get _isAndroid {
    if (kIsWeb) return false;
    try { return Platform.isAndroid; } catch (_) { return false; }
  }

  // ─── Lokasi ──────────────────────────────────────────────────────────────

  Future<PermissionStatus> checkLocation() async {
    if (_isLinux) return PermissionStatus.granted;
    return Permission.locationWhenInUse.status;
  }

  Future<PermissionStatus> requestLocation() async {
    if (_isLinux) return PermissionStatus.granted;
    return Permission.locationWhenInUse.request();
  }

  // ─── Notifikasi ──────────────────────────────────────────────────────────

  Future<PermissionStatus> checkNotification() async {
    if (_isLinux) return PermissionStatus.granted;
    return Permission.notification.status;
  }

  Future<PermissionStatus> requestNotification() async {
    if (_isLinux) return PermissionStatus.granted;
    return Permission.notification.request();
  }

  // ─── Kamera & Galeri ─────────────────────────────────────────────────────

  Future<PermissionStatus> requestCamera() async {
    if (_isLinux) return PermissionStatus.granted;
    return Permission.camera.request();
  }

  Future<PermissionStatus> requestPhotos() async {
    if (_isLinux) return PermissionStatus.granted;
    if (_isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted) return photos;
      return Permission.storage.request();
    }
    return Permission.photos.request();
  }

  // ─── Buka Settings ───────────────────────────────────────────────────────

  Future<bool> openSettings() => openAppSettings();
}
