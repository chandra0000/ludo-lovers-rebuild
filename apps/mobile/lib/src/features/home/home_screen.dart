import 'package:flutter/material.dart';

import '../match/match_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.casino_outlined, size: 76, color: Color(0xFFFFC857)),
                  const SizedBox(height: 18),
                  const Text(
                    'LUDO LOVERS',
                    style: TextStyle(
                      color: Color(0xFFFFC857),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PLAY • CONNECT • LOVE',
                    style: TextStyle(color: Colors.white70, letterSpacing: 2),
                  ),
                  const SizedBox(height: 44),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('start_local_match'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MatchScreen(),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('START LOCAL MATCH'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Foundation build · Local play only',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
