class AppConfig {
  AppConfig._();

  // Backend (from Postman environment)
  static const String baseUrl = 'https://adatitik-development.up.railway.app';

  // ─── Supabase (Realtime) ────────────────────────────────────────────────
  //
  // PENTING: tanpa kredensial ini, Supabase.initialize() menerima string kosong
  // dan websocket realtime TIDAK PERNAH konek → semua data hanya update setelah
  // refresh manual (bug "realtime gagal").
  //
  // anonKey aman ditaruh di klien (memang publik by design, dilindungi RLS).
  // Bisa di-override saat build via --dart-define untuk staging/prod.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kuivymtezqwszdkhycre.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1aXZ5bXRlenF3c3pka2h5Y3JlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MjUxODgsImV4cCI6MjA5NDAwMTE4OH0.pgBwL0a3NMRpK3Bb_5eFCloEj-nvNxLiBt7bjptbU60',
  );
}
