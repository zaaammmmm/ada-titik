// lib/core/router/app_router.dart
//
// PERUBAHAN dari versi sebelumnya:
// - Tambah route /reset-password (ResetPasswordScreen)
//   Menerima optional extra: String? (token dari ForgetPasswordScreen)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_screen.dart';
import '../../features/auth/forget_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/reset_password_screen.dart'; // ✅ NEW
import '../../features/auth/terms_and_conditions_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authProvider);

      final authed = auth.isAuthed;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!authed) {
        if (state.matchedLocation == '/' ||
            state.matchedLocation == '/splash') {
          return null;
        }
        // Halaman auth yang boleh diakses tanpa login
        final publicRoutes = [
          '/login',
          '/register',
          '/forget-password',
          '/reset-password',
          '/onboarding',
          '/terms',
        ];
        if (publicRoutes.contains(state.matchedLocation)) return null;
        return '/login';
      }

      // Authed
      if (isLoginRoute) {
        return auth.isAdmin ? '/admin' : '/home';
      }

      if (state.matchedLocation == '/admin' && !auth.isAdmin) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forget-password',
        builder: (context, state) => const ForgetPasswordScreen(),
      ),
      // ✅ NEW: Route reset password
      // extra: String? → token plaintext (dari dev_reset_token atau null)
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.extra as String?;
          return ResetPasswordScreen(initialToken: token);
        },
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScaffold(),
      ),
    ],
  );
});
