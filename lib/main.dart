// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_globals.dart';
import 'core/constants/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase init (WAJIB untuk Supabase Realtime).
  // Kredensial diambil dari AppConfig (punya default + bisa di-override
  // via --dart-define). Assert agar gagal keras kalau kosong, bukan diam.
  assert(
    AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty,
    'SUPABASE_URL / SUPABASE_ANON_KEY kosong — realtime tidak akan jalan.',
  );
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Inisialisasi notifikasi lokal (buat Android notification channel dll.)
  // Permission TIDAK diminta di sini – diminta secara kontekstual saat user
  // pertama kali membutuhkannya (NotificationScreen / HomeScreen).
  await NotificationService.instance.initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: AdaTitikApp()));
}

class AdaTitikApp extends ConsumerWidget {
  const AdaTitikApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Ada Titik?',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
