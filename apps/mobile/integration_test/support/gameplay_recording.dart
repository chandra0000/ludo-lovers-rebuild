import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';
import 'package:ludo_lovers/src/game/presentation/luxury_dice.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// QA-only entry registered by a compile-time integration-test define.
/// Production widgets, MatchSession and normal animation durations are unchanged.
void registerGameplayRecording({bool realTime = true}) {
  testWidgets(
    'seeded actual gameplay recording and authoritative assertions',
    (tester) async {
      final binding = tester.binding;
      final live = binding is LiveTestWidgetsFlutterBinding ? binding : null;
      final previousPolicy = live?.framePolicy;
      // Native recordings must render every production animation frame, not just
      // the sparse frames explicitly requested by test pumps.
      if (live != null) {
        live.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      }
      SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
      final snapshots = <SavedMatch>[];
      var elapsedMs = 0;
      var snapshotId = 0;
      void mark(String stage) => debugPrint('LUDO_QA_EVENT:${jsonEncode({
                'stage': stage,
                'elapsedMs': elapsedMs,
              })}');
      Future<void> wait(int milliseconds) async {
        // Live binding paints real frames while host recorder captures the display.
        await tester.pump(const Duration(milliseconds: 16));
        if (realTime) {
          await tester.runAsync(
            () => Future<void>.delayed(Duration(milliseconds: milliseconds)),
          );
        } else {
          for (var frame = 0; frame < milliseconds; frame += 16) {
            await tester.pump(const Duration(milliseconds: 16));
          }
        }
        elapsedMs += milliseconds;
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(String key) async {
        final target = find.byKey(Key(key));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pump();
      }

      LudoGame getGame() => snapshots.last.game;
      int progress(PlayerColor color, int pawn) => getGame()
          .players
          .singleWhere((player) => player.color == color)
          .pawnProgress[pawn];
      Future<void> mountFixture(
        String label,
        LudoGame game,
        List<int> rolls, {
        Set<PlayerColor> ai = const {},
      }) async {
        snapshots.clear();
        var nextRoll = 0;
        final profiles = MatchPlayerProfile.local(
          aiPlayers: ai,
          names: const {
            PlayerColor.orange: 'Aarya',
            PlayerColor.green: 'Renée',
            PlayerColor.magenta: 'Maya',
            PlayerColor.blue: 'Leo',
          },
        );
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              final app = const LudoLoversApp().build(context) as MaterialApp;
              return MaterialApp(
                theme: app.theme,
                debugShowCheckedModeBanner: false,
                home: MatchScreen(
                  key: ValueKey(label),
                  initialGame: game,
                  profiles: profiles,
                  aiPlayers: ai,
                  aiSeed: 17,
                  rollDice: () {
                    expect(nextRoll, lessThan(rolls.length), reason: label);
                    return rolls[nextRoll++];
                  },
                  saveMatch: (snapshot) async {
                    snapshots.add(snapshot);
                    final payload = base64Encode(
                      utf8.encode(
                        jsonEncode({
                          'fixture': label,
                          'elapsedMs': elapsedMs,
                          'snapshot': snapshot.toJson(),
                          'events': snapshot.game.events
                              .map((event) => event.runtimeType.toString())
                              .toList(),
                        }),
                      ),
                    );
                    // Android truncates individual Flutter log messages near1KB.
                    // Numbered ASCII chunks preserve full Unicode snapshots.
                    final id = snapshotId++;
                    final count = (payload.length / 480).ceil();
                    for (var part = 0; part < count; part++) {
                      final end = ((part + 1) * 480).clamp(0, payload.length);
                      debugPrint('LUDO_QA_CHUNK:$id:$part:$count:'
                          '${payload.substring(part * 480, end)}');
                    }
                    await const SavedMatchStore().save(snapshot);
                  },
                ),
              );
            },
          ),
        );
        mark(label);
        await wait(2000);
      }

      Future<void> roll(int value, {bool duplicate = false}) async {
        final version = getGame().stateVersion;
        await tap('roll_dice');
        if (duplicate) {
          await tap('roll_dice');
          await tap('roll_dice');
        }
        await wait(180);
        // On a live device the legal automatic move may finish before this
        // host assertion. Inspect the exact accepted roll version, not a clock
        // assumption about which transition is still pending.
        final rolled = snapshots
            .firstWhere(
              (snapshot) => snapshot.game.stateVersion == version + 1,
            )
            .game;
        expect(rolled.diceValue, value);
        expect(rolled.events.whereType<DiceRolled>().single.value, value);
        expect(rolled.appliedCommandIds.length, version + 1);
        if (duplicate) expect(getGame().stateVersion, version + 1);
        expect(
          tester
              .widget<LuxuryDiceButton>(find.byType(LuxuryDiceButton))
              .targetValue,
          getGame().diceValue,
          reason: 'Displayed pending result always matches authoritative state',
        );
        mark('roll-$value-authoritative');
        await wait(700);
      }

      await tester.pumpWidget(const LudoLoversApp());
      await wait(2200);
      final ack = File('/data/user/0/com.ludolovers.ludo_lovers/cache/'
          'ludo-recording-finalized');
      if (realTime && Platform.isAndroid && await ack.exists()) {
        await ack.delete();
      }
      debugPrint('LUDO_RECORD_START');
      await wait(
        3000,
      ); // Host starts native recorder before entering the match.
      try {
        await mountFixture(
          'yard-release-rolls-6-3',
          LudoGame.initial(),
          [6, 3],
        );
        await roll(6, duplicate: true);
        await tap('accessible_pawn_chooser');
        await wait(1000);
        await tester.tap(find.text('Pawn 1'));
        await tester.pump();
        // Repeated pawn input while movement is busy cannot duplicate a command.
        await tester.tap(
          find.byKey(const Key('pawn_orange_0')),
          warnIfMissed: false,
        );
        await wait(1600);
        expect(progress(PlayerColor.orange, 0), 0);
        expect(getGame().stateVersion, 2);
        expect(getGame().activePlayer, PlayerColor.orange);
        mark('yard-release-landed');
        await wait(2000);
        await roll(3);
        await wait(2000);
        expect(progress(PlayerColor.orange, 0), 3);
        expect(getGame().activePlayer, PlayerColor.green);
        expect(getGame().stateVersion, 4);
        mark('three-cell-travel-landed-turn-green');
        await wait(2000);

        // Explicit staged capture: Green progress42 shares Orange track cell3.
        // The next roll/move/capture are executed only through the live UI/session.
        await mountFixture(
          'staged-capture-orange0-green42-rolls-3-2-ai17',
          LudoGame.fromProgress(
            activePlayer: PlayerColor.orange,
            pawnProgress: {
              PlayerColor.orange: [0, -1, -1, -1],
              PlayerColor.green: [42, 10, -1, -1],
            },
          ),
          [3, 2, 1],
          ai: {PlayerColor.green},
        );
        await roll(3);
        await wait(1700);
        expect(progress(PlayerColor.orange, 0), 3);
        expect(progress(PlayerColor.green, 0), -1);
        expect(getGame().activePlayer, PlayerColor.orange);
        expect(getGame().events.whereType<PawnCaptured>(), hasLength(1));
        expect(getGame().events.whereType<ExtraTurnGranted>(), hasLength(1));
        mark('capture-and-bonus-confirmed');
        await wait(2500);
        await roll(2);
        // Let the seeded production AI think, roll and move without manual commands.
        await wait(6500);
        expect(progress(PlayerColor.orange, 0), 5);
        expect(
          snapshots.any(
            (s) => s.game.events
                .whereType<DiceRolled>()
                .any((event) => event.player == PlayerColor.green),
          ),
          isTrue,
        );
        expect(
          snapshots.any(
            (s) => s.game.events
                .whereType<PawnMoved>()
                .any((event) => event.player == PlayerColor.green),
          ),
          isTrue,
        );
        expect(getGame().activePlayer, PlayerColor.magenta);
        mark('seeded-ai-roll-move-human-handoff');
        await wait(2000);
        // No legal move progresses through the authoritative pass command.
        await roll(1);
        await wait(1400);
        expect(getGame().activePlayer, PlayerColor.blue);
        mark('no-legal-move-pass');
        await wait(2000);
        final saved = await const SavedMatchStore().load();
        expect(saved!.game.toSnapshot(), getGame().toSnapshot());
        expect(saved.profiles.first.displayName, 'Aarya');
        // Startup is now part of the continuous native clip. Keep just a short
        // final idle hold; production dice/pawn animation durations are unchanged.
        while (elapsedMs < 38000) {
          await wait(500);
        }
        expect(tester.takeException(), isNull);
      } finally {
        debugPrint('LUDO_RECORD_STOP');
        if (realTime && Platform.isAndroid) {
          await tester.runAsync(() async {
            final deadline = DateTime.now().add(const Duration(seconds: 20));
            while (!await ack.exists()) {
              if (DateTime.now().isAfter(deadline)) {
                throw TimeoutException(
                  'Host recorder finalization acknowledgement missing',
                );
              }
              await Future<void>.delayed(const Duration(milliseconds: 50));
            }
          });
        } else {
          await wait(2000);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        if (live != null) live.framePolicy = previousPolicy!;
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
