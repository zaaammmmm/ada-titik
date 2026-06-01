import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'token';
  static const _supabaseTokenKey = 'supabase_token';

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> writeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // ─── Supabase token (untuk realtime auth/RLS) ──────────────────────────
  static Future<String?> readSupabaseToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_supabaseTokenKey);
  }

  static Future<void> writeSupabaseToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_supabaseTokenKey, token);
  }

  static Future<void> clearSupabaseToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_supabaseTokenKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_supabaseTokenKey);
  }
}
