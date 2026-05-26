import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    // redirect will be re-evaluated when navigation happens.
    redirect: (context, state) {
      final auth = ref.read(authProvider);

      final authed = auth.isAuthed;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!authed) {
        // Let splash bootstrap auth.
        if (state.matchedLocation == '/' ||
            state.matchedLocation == '/splash') {
          return null;
        }
        return isLoginRoute ? null : '/login';
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
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
