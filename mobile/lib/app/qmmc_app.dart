import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/home/home_page.dart';
import '../features/prescriptions/prescriptions_page.dart';

class QmmcApp extends StatelessWidget {
  const QmmcApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/prescriptions',
          builder: (context, state) => const PrescriptionsPage(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'QMMC PD1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B5D8C),
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
