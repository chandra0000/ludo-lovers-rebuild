import 'player_color.dart';

const int sharedTrackLength = 52;
const int finishProgress = 56;
const Set<int> safeTrackCells = <int>{0, 8, 13, 21, 26, 34, 39, 47};

class LudoPlayer {
  LudoPlayer(this.color, {List<int>? pawnProgress})
      : pawnProgress = List<int>.unmodifiable(pawnProgress ?? List<int>.filled(4, -1)) {
    if (this.pawnProgress.length != 4 ||
        this.pawnProgress.any((step) => step < -1 || step > finishProgress)) {
      throw ArgumentError('Each player must have four pawns with progress -1..$finishProgress.');
    }
  }

  final PlayerColor color;
  final List<int> pawnProgress;

  LudoPlayer withPawn(int pawnIndex, int progress) {
    final next = List<int>.of(pawnProgress)..[pawnIndex] = progress;
    return LudoPlayer(color, pawnProgress: next);
  }

  bool get hasWon => pawnProgress.every((step) => step == finishProgress);
}

class LudoGame {
  LudoGame._({
    required this.players,
    required this.activePlayer,
    this.diceValue,
    this.winner,
  });

  factory LudoGame.initial() => LudoGame._(
        players: List<LudoPlayer>.unmodifiable(
          PlayerColor.turnOrder.map((color) => LudoPlayer(color)),
        ),
        activePlayer: PlayerColor.orange,
      );

  final List<LudoPlayer> players;
  final PlayerColor activePlayer;
  final int? diceValue;
  final PlayerColor? winner;

  LudoPlayer get currentPlayer => players.firstWhere((p) => p.color == activePlayer);

  List<int> legalPawnIndices({int? roll}) {
    final value = roll ?? diceValue;
    if (value == null || winner != null) return const [];
    final result = <int>[];
    for (var i = 0; i < currentPlayer.pawnProgress.length; i++) {
      final progress = currentPlayer.pawnProgress[i];
      if (progress == -1 ? value == 6 : progress + value <= finishProgress) {
        result.add(i);
      }
    }
    return List<int>.unmodifiable(result);
  }

  LudoGame roll(int value) {
    if (winner != null) throw StateError('The game has already finished.');
    if (diceValue != null) throw StateError('Move a pawn before rolling again.');
    if (value < 1 || value > 6) throw ArgumentError.value(value, 'value', 'Dice must be 1..6.');
    return LudoGame._(
      players: players,
      activePlayer: activePlayer,
      diceValue: value,
      winner: winner,
    );
  }

  LudoGame passTurn() {
    if (diceValue == null) throw StateError('Roll the dice first.');
    if (legalPawnIndices().isNotEmpty) {
      throw StateError('A legal pawn move is available.');
    }
    return LudoGame._(
      players: players,
      activePlayer: diceValue == 6 ? activePlayer : activePlayer.next,
    );
  }

  LudoGame movePawn(int pawnIndex) {
    final rollValue = diceValue;
    if (rollValue == null) throw StateError('Roll the dice first.');
    if (!legalPawnIndices().contains(pawnIndex)) {
      throw StateError('Pawn $pawnIndex cannot move with a roll of $rollValue.');
    }

    final updatedPlayers = List<LudoPlayer>.of(players);
    final playerIndex = updatedPlayers.indexWhere((p) => p.color == activePlayer);
    final player = updatedPlayers[playerIndex];
    final previous = player.pawnProgress[pawnIndex];
    final nextProgress = previous == -1 ? 0 : previous + rollValue;
    updatedPlayers[playerIndex] = player.withPawn(pawnIndex, nextProgress);

    var captured = false;
    if (nextProgress < sharedTrackLength && !safeTrackCells.contains(_trackCell(activePlayer, nextProgress))) {
      final landingCell = _trackCell(activePlayer, nextProgress);
      for (var i = 0; i < updatedPlayers.length; i++) {
        if (updatedPlayers[i].color == activePlayer) continue;
        final opponent = updatedPlayers[i];
        var changed = opponent;
        for (var pawn = 0; pawn < opponent.pawnProgress.length; pawn++) {
          final progress = opponent.pawnProgress[pawn];
          if (progress >= 0 &&
              progress < sharedTrackLength &&
              _trackCell(opponent.color, progress) == landingCell) {
            changed = changed.withPawn(pawn, -1);
            captured = true;
          }
        }
        updatedPlayers[i] = changed;
      }
    }

    final updatedCurrent = updatedPlayers[playerIndex];
    final gameWinner = updatedCurrent.hasWon ? activePlayer : null;
    final extraTurn = rollValue == 6 || captured;
    final nextPlayer = gameWinner != null || extraTurn
        ? activePlayer
        : activePlayer.next;

    return LudoGame._(
      players: List<LudoPlayer>.unmodifiable(updatedPlayers),
      activePlayer: nextPlayer,
      winner: gameWinner,
    );
  }

  int _trackCell(PlayerColor color, int progress) =>
      (color.entryIndex + progress) % sharedTrackLength;
}
