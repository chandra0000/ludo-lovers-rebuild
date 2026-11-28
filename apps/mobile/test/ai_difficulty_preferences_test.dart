import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:ludo_lovers/src/features/setup/game_setup_screen.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/ai_difficulty_preferences.dart';
import 'support/capture_artifact.dart';
import 'support/load_sdk_fonts.dart';

class _Preferences extends AiDifficultyPreferences {
  Future<LudoAiDifficulty>? preferred;
  Completer<void>? write;
  Object? failure;
  final saved = <LudoAiDifficulty>[];
  @override
  Future<LudoAiDifficulty> load() =>
      preferred ?? Future.value(LudoAiDifficulty.hard);
  @override
  Future<void> save(LudoAiDifficulty difficulty) async {
    saved.add(difficulty);
    if (failure != null) throw failure!;
    if (write != null) await write!.future;
  }
}

Future<void> _mount(
  WidgetTester tester,
  AiDifficultyPreferences preferences,
) async {
  tester.view.physicalSize = const Size(393, 873);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: GameSetupScreen(
        initialPlayerCount: 2,
        preferComputer: true,
        aiPreferences: preferences,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadSdkFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const store = AiDifficultyPreferences();
  for (final level in LudoAiDifficulty.values) {
    test('round trips ${level.name} preference', () async {
      await store.save(level);
      expect(await store.load(), level);
    });
  }
  test('missing and malformed preferences use Medium', () async {
    for (final raw in [null, 'unsupported', 42]) {
      SharedPreferences.setMockInitialValues(
        {if (raw != null) AiDifficultyPreferences.storageKey: raw},
      );
      expect(await store.load(), LudoAiDifficulty.medium);
    }
  });
  test('preference writes do not modify saved-match authority', () async {
    SharedPreferences.setMockInitialValues(
      {'saved_local_match_v1': 'existing snapshot'},
    );
    await store.save(LudoAiDifficulty.hard);
    expect(
      (await SharedPreferences.getInstance()).getString('saved_local_match_v1'),
      'existing snapshot',
    );
  });
  testWidgets('late preference load cannot replace an edited difficulty',
      (tester) async {
    final preferred = Completer<LudoAiDifficulty>();
    final preferences = _Preferences()..preferred = preferred.future;
    await _mount(tester, preferences);
    final picker = find.byKey(const Key('ai_difficulty'));
    tester
        .widget<DropdownButton<LudoAiDifficulty>>(picker)
        .onChanged!(LudoAiDifficulty.easy);
    await tester.pump();
    preferred.complete(LudoAiDifficulty.hard);
    await tester.pump();
    expect(
      tester.widget<DropdownButton<LudoAiDifficulty>>(picker).value,
      LudoAiDifficulty.easy,
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'starting freezes setup and launches one match with preferred level and explicit opposite seats',
      (tester) async {
    final preferences = _Preferences()..write = Completer<void>();
    await _mount(tester, preferences);
    final start = find.byKey(const Key('start_ai_match'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pump();
    expect(preferences.saved, [LudoAiDifficulty.hard]);
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    expect(
      tester
          .widget<DropdownButton<LudoAiDifficulty>>(
            find.byKey(const Key('ai_difficulty')),
          )
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const Key('mode_player_count')),
          )
          .onChanged,
      isNull,
    );
    await tester.tap(start);
    preferences.write!.complete();
    await tester.pumpAndSettle();
    final match = tester.widget<MatchScreen>(find.byType(MatchScreen));
    expect(match.aiDifficulty, LudoAiDifficulty.hard);
    expect(
      match.initialGame!.configuration.activePlayers,
      [PlayerColor.orange, PlayerColor.magenta],
    );
    expect(match.aiPlayers, {PlayerColor.magenta});
    expect(preferences.saved, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'optional preference save failure cannot prevent the selected match',
      (tester) async {
    final preferences = _Preferences()
      ..failure = StateError('Injected write failure');
    await _mount(tester, preferences);
    final start = find.byKey(const Key('start_ai_match'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(
      tester.widget<MatchScreen>(find.byType(MatchScreen)).aiDifficulty,
      LudoAiDifficulty.hard,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'stalled optional preference write is bounded and late completion cannot start twice',
      (tester) async {
    final preferences = _Preferences()..write = Completer<void>();
    await _mount(tester, preferences);
    final start = find.byKey(const Key('start_ai_match'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pump();
    expect(preferences.saved, hasLength(1));
    await tester.pump(const Duration(milliseconds: 2001));
    await tester.pumpAndSettle();
    expect(find.byType(MatchScreen), findsOneWidget);
    preferences.write!.complete();
    await tester.pump();
    expect(find.byType(MatchScreen), findsOneWidget);
    expect(preferences.saved, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('late preference load after disposal is safe', (tester) async {
    final pending = Completer<LudoAiDifficulty>();
    await _mount(tester, _Preferences()..preferred = pending.future);
    await tester.pumpWidget(const SizedBox());
    pending.complete(LudoAiDifficulty.hard);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'actual setup renders preferred difficulty with bundled typography',
      (tester) async {
    await store.save(LudoAiDifficulty.hard);
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          final app = const LudoLoversApp().build(context) as MaterialApp;
          return MaterialApp(
            theme: app.theme,
            home: const RepaintBoundary(
              key: Key('ai_setup_capture'),
              child:
                  GameSetupScreen(initialPlayerCount: 2, preferComputer: true),
            ),
          );
        },
      ),
    );
    final picker = find.byKey(const Key('ai_difficulty'));
    await tester.ensureVisible(picker);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DropdownButton<LudoAiDifficulty>>(picker).value,
      LudoAiDifficulty.hard,
    );
    await captureArtifact(
      tester,
      'preferred-ai-difficulty-393x873',
      key: const Key('ai_setup_capture'),
    );
    await tester.pumpWidget(const SizedBox());
  });
}
