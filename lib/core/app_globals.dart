// lib/core/app_globals.dart
//
// Messenger key global supaya SnackBar (mis. welcome berbasis role saat login)
// tetap tampil setelah pindah halaman via go_router (context lama sudah hilang).

import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
