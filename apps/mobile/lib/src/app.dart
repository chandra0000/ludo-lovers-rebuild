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
        // Gameplay uses dark floating feedback surfaces. Material3's inverse
        // snackbar text is dark, so define both colors as one readable pair.
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF211A0D),
          contentTextStyle: TextStyle(color: Color(0xFFFFE3A0)),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
