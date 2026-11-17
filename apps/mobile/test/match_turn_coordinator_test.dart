import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_command_controller.dart';
import 'package:ludo_lovers/src/features/match/match_turn_coordinator.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('paused/disposed coordinator never consumes a human roll',
      (tester) async {
    var active = false;
    var rolls = 0;
    var diceBusy = false;
    final controller = MatchCommandController(
      MatchSession.local(matchId: 'guard', game: LudoGame.initial()),
    );
    final turns = MatchTurnCoordinator(
      controller: controller,
      aiPlayers: const {},
      aiSeed: 1,
      difficulty: LudoAiDifficulty.medium,
      isActive: () => active,
      movementBusy: () => false,
      diceBusy: () => diceBusy,
      rollHuman: () {
        rolls++;
        return 6;
      },
      execute: controller.execute,
      onRollAccepted: (_) => diceBusy = true,
      onMoveAccepted: (_, __, ___) {},
      onDiceSettled: () => diceBusy = false,
      onChanged: () {},
      onPenalty: () {},
    );
    expect(turns.roll(), isFalse);
    expect(rolls, 0);
    active = true;
    expect(turns.roll(), isTrue);
    expect(turns.roll(), isFalse);
    turns.completeDice();
    turns.completeDice();
    expect(controller.game.stateVersion, 1);
    expect(controller.game.diceValue, 6);
    expect(rolls, 1);
    turns.dispose();
    expect(turns.roll(), isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(controller.game.stateVersion, 1);
  });

  testWidgets('disposing pending AI scheduling rejects its delayed command',
      (tester) async {
    final controller = MatchCommandController(
      MatchSession.local(matchId: 'ai', game: LudoGame.initial()),
    );
    var rolls = 0;
    final turns = MatchTurnCoordinator(
      controller: controller,
      aiPlayers: const {PlayerColor.orange},
      aiSeed: 1,
      difficulty: LudoAiDifficulty.hard,
      isActive: () => true,
      movementBusy: () => false,
      diceBusy: () => false,
      rollHuman: () => throw StateError('AI must not use human RNG'),
      execute: controller.execute,
      onRollAccepted: (_) => rolls++,
      onMoveAccepted: (_, __, ___) {},
      onDiceSettled: () {},
      onChanged: () {},
      onPenalty: () {},
    );
    turns.scheduleAi();
    turns.dispose();
    await tester.pump(const Duration(seconds: 2));
    expect(rolls, 0);
    expect(controller.game.stateVersion, 0);
  });
}
