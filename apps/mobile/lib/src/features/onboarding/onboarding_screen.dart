import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;
  bool _saving = false;

  static const _content = <({IconData icon, String title, String body})>[
    (
      icon: Icons.casino_rounded,
      title: 'WELCOME TO LUDO LOVERS',
      body: 'A premium local Ludo experience. Bring friends together around '
          'one shared board and race all four colours home.',
    ),
    (
      icon: Icons.route_rounded,
      title: 'PLAY YOUR WAY',
      body: 'Choose a local pass-and-play match or add seeded AI opponents. '
          'The game engine validates every dice roll and pawn move.',
    ),
    (
      icon: Icons.groups_rounded,
      title: 'FOUR COLOURS. ONE BOARD.',
      body: 'Orange, Green, Magenta and Blue each have four pawns. More modes '
          'will appear only after their rules are implemented and verified.',
    ),
  ];

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_completed_v1', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('skip_onboarding'),
                  onPressed: _finish,
                  child: const Text('SKIP'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  key: const Key('onboarding_pages'),
                  controller: _pages,
                  itemCount: _content.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) {
                    final item = _content[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF211A0D),
                            border: Border.all(
                              color: const Color(0x99FFC857),
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            size: 62,
                            color: const Color(0xFFFFC857),
                          ),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFC857),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  _content.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _page ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? const Color(0xFFFFC857)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('onboarding_next'),
                  onPressed: _saving
                      ? null
                      : _page == _content.length - 1
                          ? _finish
                          : () => _pages.nextPage(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOut,
                              ),
                  child: Text(
                    _page == _content.length - 1 ? 'GET STARTED' : 'NEXT',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
