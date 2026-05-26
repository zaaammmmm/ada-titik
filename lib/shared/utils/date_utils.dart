// lib/shared/utils/date_utils.dart

import 'package:intl/intl.dart';

/// Helper untuk format tanggal/waktu.
/// Mengkonversi ISO 8601 string ke format "2 jam yang lalu".
class DateUtils {
  DateUtils._();

  /// Parse ISO 8601 date string dan return formatted "time ago".
  /// Contoh input: "2026-05-20T08:00:00.000Z"
  /// Contoh output: "2 jam yang lalu"
  static String formatTimeAgo(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) {
      return 'Baru';
    }

    try {
      // Parse ISO 8601 format
      final dateTime = DateTime.tryParse(isoDate);
      if (dateTime == null) {
        return isoDate;
      }

      return _timeAgo(dateTime);
    } catch (e) {
      return 'Baru';
    }
  }

  /// Alternative: terima DateTime langsung
  static String formatTimeAgoFromDateTime(DateTime dateTime) {
    return _timeAgo(dateTime);
  }

  static String _timeAgo(DateTime dateTime) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(dateTime);

    // Dalam hitungan detik
    if (diff.inSeconds < 60) {
      return 'Baru saja';
    }

    // Dalam hitungan menit
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return '$minutes menit yang lalu';
    }

    // Dalam hitungan jam
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours jam yang lalu';
    }

    // Dalam hitungan hari
    if (diff.inDays < 7) {
      final days = diff.inDays;
      if (days == 1) {
        return 'Kemarin';
      }
      return '$days hari yang lalu';
    }

    // Dalam hitungan minggu
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      if (weeks == 1) {
        return 'Minggu lalu';
      }
      return '$weeks minggu yang lalu';
    }

    // Dalam hitungan bulan
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      if (months == 1) {
        return 'Bulan lalu';
      }
      return '$months bulan yang lalu';
    }

    // Lebih dari tahun
    final years = (diff.inDays / 365).floor();
    if (years == 1) {
      return 'Tahun lalu';
    }
    return '$years tahun yang lalu';
  }

  /// Format tanggal Indonesia.
  /// Contoh: "20 Mei 2026"
  static String formatDateId(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) {
      return '';
    }

    try {
      final dateTime = DateTime.tryParse(isoDate);
      if (dateTime == null) {
        return isoDate;
      }

      return DateFormat('d MMMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return isoDate;
    }
  }

  /// Format tanggal dan waktu Indonesia.
  /// Contoh: "20 Mei 2026, 08.00"
  static String formatDateTimeId(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) {
      return '';
    }

    try {
      final dateTime = DateTime.tryParse(isoDate);
      if (dateTime == null) {
        return isoDate;
      }

      return DateFormat('d MMMM yyyy, HH.mm', 'id_ID').format(dateTime);
    } catch (e) {
      return isoDate;
    }
  }
}