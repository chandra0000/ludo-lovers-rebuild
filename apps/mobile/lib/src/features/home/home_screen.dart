import 'package:flutter/material.dart';

import '../setup/game_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _gold = Color(0xFFFFC857);
  static const _background = Color(0xFF080808);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final logoSize = (screenSize.width * 0.48)
        .clamp(144.0, screenSize.height < 700 ? 164.0 : 200.0)
        .toDouble();

    return Scaffold(
      backgroundColor: _background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF17110A),
              Color(0xFF080808),
              Color(0xFF030303),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: logoSize,
                        height: logoSize,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: _gold.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55FFC857),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/branding/ludo_lovers_icon.webp',
                            key: const Key('brand_logo'),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) =>
                                const ColoredBox(
                              color: Color(0xFF141722),
                              child: Center(
                                child: Icon(
                                  Icons.casino,
                                  color: _gold,
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'LUDO LOVERS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _gold,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'PLAY • CONNECT • LOVE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Bring everyone to one board.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Roll the dice, move your glass pawns and race all four '
                        'colours home. More modes are being added after their '
                        'rules are verified.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('open_game_setup'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: const Color(0xFF17110A),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const GameSetupScreen(),
                            ),
                          ),
                          child: const Text(
                            'PLAY NOW',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Four colours · Four pawns each · One shared board',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
