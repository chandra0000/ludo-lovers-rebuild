import 'board_geometry.dart';
import 'player_color.dart';

enum TeamUpTeam { a, b }

enum TeamCaptureCause { arrival, protectedDeparture }

typedef TeamUpPawn = ({PlayerColor color, int index, int progress});

class TeamUpCapture {
  const TeamUpCapture(this.byTeam, this.victim, this.pawnIndex, this.cause);
  final TeamUpTeam byTeam;
  final PlayerColor victim;
  final int pawnIndex;
  final TeamCaptureCause cause;
}

class TeamUpResolution {
  TeamUpResolution(Map<int, TeamUpTeam> priority, List<TeamUpCapture> captures)
      : priority = Map.unmodifiable(priority),
        captures = List.unmodifiable(captures);
  final Map<int, TeamUpTeam> priority;
  final List<TeamUpCapture> captures;
}

/// Pure Team Up policies shared by evaluation and accepted engine transitions.
/// Geometry remains the rebuild's approved contract, not legacy route data.
class TeamUpPolicy {
  static TeamUpTeam teamFor(PlayerColor color) => switch (color) {
        PlayerColor.orange || PlayerColor.magenta => TeamUpTeam.a,
        PlayerColor.green || PlayerColor.blue => TeamUpTeam.b,
      };
  static PlayerColor teammate(PlayerColor color) => switch (color) {
        PlayerColor.orange => PlayerColor.magenta,
        PlayerColor.magenta => PlayerColor.orange,
        PlayerColor.green => PlayerColor.blue,
        PlayerColor.blue => PlayerColor.green,
      };
  static PlayerColor? recipient(
    PlayerColor scheduled,
    Set<PlayerColor> finished,
  ) =>
      !finished.contains(scheduled)
          ? scheduled
          : !finished.contains(teammate(scheduled))
              ? teammate(scheduled)
              : null;
  static bool hasWon(TeamUpTeam team, Set<PlayerColor> finished) =>
      PlayerColor.turnOrder
          .where((c) => teamFor(c) == team)
          .every(finished.contains);
  static ({PlayerColor scheduled, PlayerColor active}) nextTurn(
    PlayerColor from,
    Set<PlayerColor> finished,
  ) {
    var seat = from;
    for (var i = 0; i < 4; i++) {
      seat = seat.next;
      final active = recipient(seat, finished);
      if (active != null) return (scheduled: seat, active: active);
    }
    throw StateError('No unfinished team can receive a turn');
  }

  static int? cell(TeamUpPawn pawn) =>
      pawn.progress >= 0 && pawn.progress < BoardGeometry.playerTrackLength
          ? BoardGeometry.physicalTrackCell(pawn.color, pawn.progress)
          : null;

  static void validate(
    Iterable<TeamUpPawn> pawns,
    Map<int, TeamUpTeam> priority,
  ) {
    final teamsByCell = <int, Set<TeamUpTeam>>{};
    for (final pawn in pawns) {
      final at = cell(pawn);
      if (at == null || BoardGeometry.safeTrackCells.contains(at)) continue;
      teamsByCell.putIfAbsent(at, () => {}).add(teamFor(pawn.color));
    }
    for (final entry in priority.entries) {
      if (entry.key < 0 ||
          entry.key >= BoardGeometry.trackLength ||
          BoardGeometry.safeTrackCells.contains(entry.key) ||
          teamsByCell[entry.key]?.length != 2) {
        throw const FormatException('Invalid Team Up capture priority');
      }
    }
    for (final entry in teamsByCell.entries) {
      if (entry.value.length == 2 && !priority.containsKey(entry.key)) {
        throw const FormatException(
          'Mixed unsafe stacks require explicit priority',
        );
      }
    }
  }

  /// Receives the post-movement pawn locations, before stack consequences.
  static TeamUpResolution resolve({
    required List<TeamUpPawn> pawns,
    required PlayerColor actor,
    required int previous,
    required int destination,
    required Map<int, TeamUpTeam> priority,
  }) {
    final occupants = List<TeamUpPawn>.of(pawns);
    final next = Map<int, TeamUpTeam>.of(priority);
    final captures = <TeamUpCapture>[];
    List<TeamUpPawn> atCell(int at) =>
        occupants.where((p) => cell(p) == at).toList();
    void capture(
      List<TeamUpPawn> victims,
      TeamUpTeam by,
      TeamCaptureCause cause,
    ) {
      for (final victim in victims) {
        final index = occupants.indexWhere(
          (p) => p.color == victim.color && p.index == victim.index,
        );
        occupants[index] =
            (color: victim.color, index: victim.index, progress: -1);
        captures.add(TeamUpCapture(by, victim.color, victim.index, cause));
      }
    }

    if (previous >= 0 && previous < BoardGeometry.playerTrackLength) {
      final source = BoardGeometry.physicalTrackCell(actor, previous);
      final owner = next[source];
      if (owner != null) {
        final remaining = atCell(source);
        final owners =
            remaining.where((p) => teamFor(p.color) == owner).toList();
        final protected =
            remaining.where((p) => teamFor(p.color) != owner).toList();
        if (owners.isEmpty || protected.isEmpty) {
          next.remove(source);
        } else if (teamFor(actor) != owner) {
          capture(protected, owner, TeamCaptureCause.protectedDeparture);
          next.remove(source);
        }
      }
    }
    if (destination >= 0 && destination < BoardGeometry.playerTrackLength) {
      final target = BoardGeometry.physicalTrackCell(actor, destination);
      if (!BoardGeometry.safeTrackCells.contains(target)) {
        final arriving = teamFor(actor);
        final remaining = atCell(target);
        final friendly =
            remaining.where((p) => teamFor(p.color) == arriving).toList();
        final opposing =
            remaining.where((p) => teamFor(p.color) != arriving).toList();
        if (opposing.isEmpty) {
          next.remove(target);
        } else {
          next[target] = arriving;
          if (friendly.length == opposing.length) {
            capture(opposing, arriving, TeamCaptureCause.arrival);
            next.remove(target);
          }
        }
      }
    }
    return TeamUpResolution(next, captures);
  }
}
