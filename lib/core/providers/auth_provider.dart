import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/auth_storage.dart';
import '../../core/services/supabase_session.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../shared/models/models.dart';

class AuthState {
  final String? token;
  final UserModel? user;
  final bool loading;
  final String? error;

  const AuthState({
    this.token,
    this.user,
    this.loading = false,
    this.error,
  });

  bool get isAuthed => token != null && token!.isNotEmpty && user != null;
  bool get isAdmin => (user?.role ?? '').toLowerCase() == 'admin';
  bool get isDonatur => (user?.role ?? '').toLowerCase() == 'donatur';
  bool get isKomunitas => (user?.role ?? '').toLowerCase() == 'komunitas';

  AuthState copyWith({
    String? token,
    UserModel? user,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      loading: loading ?? this.loading,
      // Tanpa ini, setiap copyWith tanpa `error:` diam-diam menghapus error
      // yang sudah di-set sebelumnya (bug: pesan error tertelan).
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  // State awal: loading = TRUE agar router menahan di splash
  // dan tidak langsung redirect ke /login sebelum token dicek.
  AuthNotifier() : super(const AuthState(loading: true));

  final _repo = const DonationRepository();
  bool _initCalled = false;

  /// Baca token tersimpan dan fetch profile.
  /// Dipanggil dari SplashScreen — router menunggu di '/' selama loading=true.
  Future<void> init() async {
    if (_initCalled) return;
    _initCalled = true;

    // loading sudah true dari constructor, tidak perlu set ulang

    final token = await AuthStorage.readToken();
    if (token == null || token.isEmpty) {
      // Tidak ada token → langsung selesai, router akan redirect ke /login
      state = const AuthState(loading: false);
      return;
    }

    try {
      final profile = await _repo.getProfile();
      // Token valid → set user, router akan redirect ke /home atau /admin
      state = AuthState(token: token, user: profile, loading: false);
    } catch (_) {
      // Token expired / invalid → hapus dan arahkan ke login
      await AuthStorage.clear();
      state = const AuthState(loading: false);
    }
  }

  Future<void> refreshProfile() async {
    state = state.copyWith(loading: true, clearError: true);
    final token = await AuthStorage.readToken();
    if (token == null || token.isEmpty) {
      state = const AuthState();
      return;
    }
    try {
      final profile = await _repo.getProfile();
      state = state.copyWith(token: token, user: profile, loading: false);
    } catch (_) {
      await AuthStorage.clear();
      state = const AuthState(loading: false);
    }
  }

  Future<void> logout() async {
    await AuthStorage.clear();
    await SupabaseSession.clear();
    _initCalled = false;
    state = const AuthState(loading: false);
  }

  void setTokenAndUser({required String token, required UserModel user}) {
    _initCalled = true;
    state = AuthState(token: token, user: user, loading: false);
  }

  void setError(String msg) {
    state = state.copyWith(error: msg, loading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
  // init() TIDAK dipanggil di sini — dipanggil dari SplashScreen._bootstrap()
  // State awal loading=true membuat router menunggu di splash secara otomatis.
});
