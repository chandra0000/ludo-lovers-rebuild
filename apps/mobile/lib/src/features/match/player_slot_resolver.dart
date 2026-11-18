import '../../game/domain/ludo_game.dart';
import '../../game/domain/match_player_profile.dart';
import '../../game/domain/player_color.dart';
import '../../game/domain/team_up_policy.dart';

class PlayerSlot {
  const PlayerSlot({
    required this.profile,
    required this.participating,
    required this.active,
    this.team,
  });
  final MatchPlayerProfile profile;
  final bool participating;
  final bool active;
  final TeamUpTeam? team;
}

/// Visual quadrant order is deliberately independent of scheduled turn order.
class PlayerSlotResolver {
  static const top = [PlayerColor.orange, PlayerColor.green];
  static const bottom = [PlayerColor.blue, PlayerColor.magenta];
  static List<PlayerSlot> resolve(
    LudoGame game,
    List<MatchPlayerProfile> profiles,
  ) =>
      List.unmodifiable(
        [...top, ...bottom].map(
          (color) => PlayerSlot(
            profile: profiles.singleWhere((p) => p.color == color),
            participating: game.configuration.activePlayers.contains(color),
            active: game.winner == null && game.activePlayer == color,
            team: game.configuration.isTeamUp
                ? TeamUpPolicy.teamFor(color)
                : null,
          ),
        ),
      );
}
