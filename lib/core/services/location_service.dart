// lib/core/services/location_service.dart
//
// LocationService – cross-platform (Android & Linux desktop).
//
// Strategi:
//   1. Cek apakah service lokasi aktif.
//   2. Minta permission jika belum diberikan.
//   3. Dapatkan posisi saat ini; fallback ke last-known jika gagal.
//   4. Di Linux desktop (geolocator kadang tidak support provider GPS),
//      tangkap exception dan kembalikan null agar UI bisa menampilkan
//      pesan yang informatif, bukan crash.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Hasil dari [LocationService.getLocationWithStatus].
enum LocationStatus {
  /// Posisi berhasil didapatkan.
  success,

  /// Permission ditolak oleh user.
  permissionDenied,

  /// Permission ditolak secara permanen (harus buka Settings).
  permissionDeniedForever,

  /// Location service (GPS/network) dimatikan di sistem.
  serviceDisabled,

  /// Plugin tidak tersedia di platform ini (misalnya Linux tanpa GeoClue).
  pluginUnavailable,

  /// Error lain yang tidak terduga.
  unknown,
}

class LocationResult {
  final Position? position;
  final LocationStatus status;
  final String message;

  const LocationResult({
    required this.position,
    required this.status,
    required this.message,
  });

  bool get isSuccess => status == LocationStatus.success && position != null;
}

class LocationService {
  LocationService._();

  static const LatLng defaultCenter = LatLng(-7.7956, 110.3695);

  static final LocationService instance = LocationService._();

  // ─── Platform helper ────────────────────────────────────────────────────

  /// Apakah platform ini adalah Linux desktop (bukan Android/iOS/Web).
  bool get _isLinuxDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  // ─── Safe wrappers ───────────────────────────────────────────────────────

  Future<bool> _safeIsServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<LocationPermission> _safeCheckPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  Future<LocationPermission> _safeRequestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Mendapatkan posisi dengan status lengkap.
  ///
  /// Ini adalah metode utama yang sebaiknya digunakan oleh UI, karena
  /// mengembalikan [LocationResult] yang berisi status dan pesan yang
  /// dapat langsung ditampilkan ke pengguna.
  Future<LocationResult> getLocationWithStatus() async {
    // Di Linux desktop: coba dulu, jika plugin tidak ada, kembalikan status jelas.
    if (_isLinuxDesktop) {
      return _getLocationLinux();
    }
    return _getLocationMobile();
  }

  /// Versi kompatibel (backward-compat): kembalikan [Position?] saja.
  Future<Position?> getCurrentPosition() async {
    final result = await getLocationWithStatus();
    return result.position;
  }

  // ─── Linux desktop implementation ────────────────────────────────────────

  Future<LocationResult> _getLocationLinux() async {
    // GeoClue2 (backend lokasi Linux) mungkin tidak aktif atau tidak dikonfigurasi.
    // Kita coba tapi siap fallback gracefully.
    try {
      // 1) Cek service
      final serviceEnabled = await _safeIsServiceEnabled();

      // 2) Permission
      var permission = await _safeCheckPermission();
      if (permission == LocationPermission.denied) {
        permission = await _safeRequestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          position: null,
          status: LocationStatus.permissionDeniedForever,
          message:
              'Izin lokasi ditolak permanen. Buka Pengaturan sistem untuk mengaktifkan kembali.',
        );
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult(
          position: null,
          status: LocationStatus.permissionDenied,
          message: 'Izin lokasi ditolak. Mohon izinkan akses lokasi.',
        );
      }

      if (!serviceEnabled) {
        // Di Linux, coba last-known dulu sebelum menyerah.
        final last = await _tryLastKnown();
        if (last != null) {
          return LocationResult(
            position: last,
            status: LocationStatus.success,
            message: 'Menggunakan posisi terakhir yang diketahui.',
          );
        }
        return const LocationResult(
          position: null,
          status: LocationStatus.serviceDisabled,
          message:
              'Layanan lokasi dinonaktifkan. Aktifkan lokasi di pengaturan sistem.',
        );
      }

      // 3) Dapatkan posisi
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // lebih cepat di desktop
        timeLimit: const Duration(seconds: 15),
      );
      return LocationResult(
        position: pos,
        status: LocationStatus.success,
        message: 'Lokasi berhasil didapatkan.',
      );
    } on LocationServiceDisabledException {
      return const LocationResult(
        position: null,
        status: LocationStatus.serviceDisabled,
        message:
            'Layanan lokasi dinonaktifkan. Aktifkan lokasi di pengaturan sistem.',
      );
    } on PermissionDeniedException {
      return const LocationResult(
        position: null,
        status: LocationStatus.permissionDenied,
        message: 'Izin lokasi ditolak.',
      );
    } catch (e) {
      // Plugin mungkin tidak tersedia (GeoClue tidak ada).
      final msg = e.toString().toLowerCase();
      if (msg.contains('plugin') ||
          msg.contains('not registered') ||
          msg.contains('geoclue') ||
          msg.contains('methodchannel') ||
          msg.contains('unavailable')) {
        return LocationResult(
          position: null,
          status: LocationStatus.pluginUnavailable,
          message:
              'Layanan lokasi tidak tersedia di perangkat ini. Pilih lokasi manual di peta.',
        );
      }
      return LocationResult(
        position: null,
        status: LocationStatus.unknown,
        message: 'Gagal mendapatkan lokasi: $e',
      );
    }
  }

  // ─── Android / iOS implementation ────────────────────────────────────────

  Future<LocationResult> _getLocationMobile() async {
    try {
      // 1) Cek service
      final serviceEnabled = await _safeIsServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          position: null,
          status: LocationStatus.serviceDisabled,
          message:
              'GPS / layanan lokasi dinonaktifkan. Aktifkan di pengaturan perangkat.',
        );
      }

      // 2) Permission
      var permission = await _safeCheckPermission();
      if (permission == LocationPermission.denied) {
        permission = await _safeRequestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          position: null,
          status: LocationStatus.permissionDeniedForever,
          message:
              'Izin lokasi ditolak permanen. Buka Pengaturan Aplikasi untuk mengaktifkan.',
        );
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult(
          position: null,
          status: LocationStatus.permissionDenied,
          message: 'Izin lokasi diperlukan untuk fitur ini.',
        );
      }

      // 3) Dapatkan posisi dengan timeout
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );
        return LocationResult(
          position: pos,
          status: LocationStatus.success,
          message: 'Lokasi berhasil didapatkan.',
        );
      } on TimeoutException {
        // Timeout: coba last known
        final last = await _tryLastKnown();
        if (last != null) {
          return LocationResult(
            position: last,
            status: LocationStatus.success,
            message: 'Menggunakan posisi terakhir (GPS timeout).',
          );
        }
        return const LocationResult(
          position: null,
          status: LocationStatus.unknown,
          message: 'GPS timeout. Pastikan Anda berada di tempat dengan sinyal.',
        );
      } catch (_) {
        // Fallback ke last known
        final last = await _tryLastKnown();
        if (last != null) {
          return LocationResult(
            position: last,
            status: LocationStatus.success,
            message: 'Menggunakan posisi terakhir yang diketahui.',
          );
        }
        return const LocationResult(
          position: null,
          status: LocationStatus.unknown,
          message: 'Tidak dapat mendapatkan lokasi saat ini.',
        );
      }
    } catch (e) {
      return LocationResult(
        position: null,
        status: LocationStatus.unknown,
        message: 'Error lokasi: $e',
      );
    }
  }

  Future<Position?> _tryLastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Stream posisi – digunakan oleh Maps screen untuk auto-update lokasi user.
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  /// Buka pengaturan lokasi sistem (Android: Location Settings).
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {}
  }

  /// Buka pengaturan aplikasi (untuk unblock permissionDeniedForever).
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  static LatLng positionToLatLng(Position p) => LatLng(p.latitude, p.longitude);
}
