// lib/core/services/supabase_session.dart
//
// Menjembatani auth aplikasi (JWT custom dari backend) dengan Supabase Realtime.
//
// Tabel `notifications`, `chat_messages`, `chat_conversations` punya RLS yang
// mensyaratkan `auth.uid() = user_id`. Klien Supabase Flutter default-nya ANON
// (auth.uid() = NULL) sehingga subscribe ke tabel-tabel itu DIAM TANPA DATA.
//
// Backend sudah mencetak `supabase_token` (JWT dengan claim sub = user UUID)
// saat login dan menyediakan GET /api/auth/supabase-token untuk refresh.
// Di sini kita pasang token tersebut ke realtime client lewat setAuth().

import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/api_client.dart';
import '../network/auth_storage.dart';

class SupabaseSession {
  SupabaseSession._();

  /// Pasang Supabase token ke realtime client supaya auth.uid() terisi.
  static void apply(String supabaseToken) {
    if (supabaseToken.isEmpty) return;
    try {
      Supabase.instance.client.realtime.setAuth(supabaseToken);
    } catch (e) {
      // Jangan ganggu flow login kalau gagal — realtime hanya jadi anonymous.
      // ignore: avoid_print
      print('SupabaseSession.apply gagal: $e');
    }
  }

  /// Simpan token sekaligus pasang ke realtime.
  static Future<void> setToken(String supabaseToken) async {
    if (supabaseToken.isEmpty) return;
    await AuthStorage.writeSupabaseToken(supabaseToken);
    apply(supabaseToken);
  }

  /// Dipanggil saat boot (SplashScreen) untuk akun yang sudah login:
  /// pakai token tersimpan, lalu refresh dari backend (token Supabase TTL 1 jam,
  /// lebih pendek dari sesi app) agar realtime tetap authenticated.
  static Future<void> restore() async {
    final cached = await AuthStorage.readSupabaseToken();
    if (cached != null && cached.isNotEmpty) {
      apply(cached);
    }
    await refreshFromBackend();
  }

  /// Mint ulang Supabase token via backend (butuh JWT app valid).
  static Future<void> refreshFromBackend() async {
    try {
      final res = await ApiClient.get<Map<String, dynamic>>(
        '/api/auth/supabase-token',
      );
      final token = res.data?['supabase_token'];
      if (token is String && token.isNotEmpty) {
        await setToken(token);
      }
    } catch (_) {
      // Diam saja — token lama (jika ada) tetap dipakai.
    }
  }

  /// Bersihkan saat logout.
  static Future<void> clear() async {
    await AuthStorage.clearSupabaseToken();
    try {
      // Kembalikan realtime ke anon dengan anon key.
      Supabase.instance.client.realtime.setAuth(null);
    } catch (_) {}
  }
}
