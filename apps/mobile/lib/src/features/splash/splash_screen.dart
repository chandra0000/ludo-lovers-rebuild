import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Displays the approved splash artwork without cropping or stretching it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 1800), _navigate);
  }

  Future<void> _navigate() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final completed = preferences.getBool('onboarding_completed_v1') ?? false;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            completed ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.expand(
          child: Image.asset(
            'assets/images/splash/splash_background.webp',
            key: const Key('splash_background'),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
}
