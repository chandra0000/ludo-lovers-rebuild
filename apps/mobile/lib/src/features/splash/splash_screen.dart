import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_typography.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// No branding timer: leave once preferences are ready and the app is resumed.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.loadOnboarding});
  final Future<bool> Function()? loadOnboarding;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {
  bool? _completed;
  bool _failed = false;
  bool _navigated = false;
  bool _holdsFirstFrame = false;
  int _attempt = 0;
  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    // Keep the native branded window until the first destination is ready;
    // publishing an asset-loading Flutter frame exposes an empty background.
    if (!binding.firstFrameRasterized) {
      binding.deferFirstFrame();
      _holdsFirstFrame = true;
    }
    binding.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final attempt = ++_attempt;
    setState(() => _failed = false);
    try {
      final completed = await (widget.loadOnboarding?.call() ??
              SharedPreferences.getInstance().then(
                (prefs) => prefs.getBool('onboarding_completed_v1') ?? false,
              ))
          .timeout(const Duration(seconds: 8));
      if (!mounted || attempt != _attempt) return;
      _completed = completed;
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
      WidgetsBinding.instance.scheduleFrame();
    } catch (_) {
      if (mounted && attempt == _attempt) {
        setState(() => _failed = true);
        _releaseFirstFrame();
      }
    }
  }

  void _navigate() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!mounted ||
        _completed == null ||
        _navigated ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _completed! ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
    _releaseFirstFrame();
  }

  void _releaseFirstFrame() {
    if (_holdsFirstFrame) {
      _holdsFirstFrame = false;
      WidgetsBinding.instance.allowFirstFrame();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _navigate();
  }

  @override
  void dispose() {
    _attempt++;
    _releaseFirstFrame();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTypography.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/branding/ludo_lovers_icon.webp',
                    key: const Key('splash_background'),
                    width: 192,
                    height: 192,
                    fit: BoxFit.contain,
                    semanticLabel: 'Ludo Lovers',
                  ),
                  if (_failed) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Unable to start. Check available storage and try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('startup_retry'),
                      onPressed: _initialize,
                      child: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
