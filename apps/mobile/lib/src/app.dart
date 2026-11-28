import 'package:flutter/material.dart';

import 'theme/app_typography.dart';

import 'features/splash/splash_screen.dart';

class LudoLoversApp extends StatelessWidget {
  const LudoLoversApp({super.key, this.onFirstViewReady});
  final VoidCallback? onFirstViewReady;

  static Widget _pressFeedback(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) =>
      AnimatedScale(
        scale: states.contains(WidgetState.pressed) ? .95 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 80),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFC857);
    return MaterialApp(
      title: 'Ludo Lovers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Nunito',
        fontFamilyFallback: AppTypography.fallback,
        textTheme: AppTypography.textTheme,
        appBarTheme: const AppBarTheme(titleTextStyle: AppTypography.heading),
        dialogTheme: const DialogThemeData(
          titleTextStyle: AppTypography.heading,
          contentTextStyle: AppTypography.body,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            textStyle: AppTypography.button,
            minimumSize: const Size(48, 48),
            foregroundBuilder: _pressFeedback,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: AppTypography.button,
            minimumSize: const Size(48, 48),
            foregroundBuilder: _pressFeedback,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: AppTypography.button,
            minimumSize: const Size(48, 48),
            foregroundBuilder: _pressFeedback,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: AppTypography.button,
            minimumSize: const Size(48, 48),
            foregroundBuilder: _pressFeedback,
          ),
        ),
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
          contentTextStyle: AppTypography.body,
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(onFirstViewReady: onFirstViewReady),
    );
  }
}
