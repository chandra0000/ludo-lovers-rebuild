import 'package:flutter/material.dart';

import 'features/splash/splash_screen.dart';

class LudoLoversApp extends StatelessWidget {
  const LudoLoversApp({super.key});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFC857);
    return MaterialApp(
      title: 'Ludo Lovers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080808),
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: Color(0xFFFF8928),
          surface: Color(0xFF151515),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
