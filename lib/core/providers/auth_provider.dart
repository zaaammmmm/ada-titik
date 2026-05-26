import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/auth_storage.dart';
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
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _repo = const DonationRepository();

  Future<void> init() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, error: null);

    final token = await AuthStorage.readToken();
    if (token == null || token.isEmpty) {
      state = const AuthState();
      return;
    }

    try {
      final profile = await _repo.getProfile();
      state = state.copyWith(token: token, user: profile, loading: false);
    } catch (e) {
      await AuthStorage.clear();
      state = const AuthState(loading: false);
    }
  }

  Future<void> refreshProfile() async {
    state = state.copyWith(loading: true, error: null);
    final token = await AuthStorage.readToken();
    if (token == null || token.isEmpty) {
      state = const AuthState();
      return;
    }

    final profile = await _repo.getProfile();
    state = state.copyWith(token: token, user: profile, loading: false);
  }

  Future<void> logout() async {
    await AuthStorage.clear();
    state = const AuthState();
  }

  void setTokenAndUser({required String token, required UserModel user}) {
    state =
        state.copyWith(token: token, user: user, loading: false, error: null);
  }

  void setError(String msg) {
    state = state.copyWith(error: msg, loading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier();
  // Fire and forget; splash/router guard will rely on state after init.
  unawaited(notifier.init());
  return notifier;
});

// ignore: non_constant_identifier_names
void unawaited(Future<void> f) {}
