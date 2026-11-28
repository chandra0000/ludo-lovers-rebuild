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
    this.thinking = false,
  });
  final MatchPlayerProfile profile;
  final bool participating;
  final bool active;
  final TeamUpTeam? team;
  final bool thinking;
}

/// Visual quadrant order is deliberately independent of scheduled turn order.
class PlayerSlotResolver {
  static const top = [PlayerColor.orange, PlayerColor.green];
  static const bottom = [PlayerColor.blue, PlayerColor.magenta];
  static List<PlayerSlot> resolve(
    LudoGame game,
    List<MatchPlayerProfile> profiles, {
    PlayerColor? thinkingPlayer,
    PlayerColor? presentedPlayer,
  }) =>
      List.unmodifiable(
        [...top, ...bottom].map(
          (color) => PlayerSlot(
            profile: profiles.singleWhere((p) => p.color == color),
            participating: game.configuration.activePlayers.contains(color),
            thinking: thinkingPlayer == color,
            active: game.winner == null &&
                (presentedPlayer ?? game.activePlayer) == color,
            team: game.configuration.isTeamUp
                ? TeamUpPolicy.teamFor(color)
                : null,
          ),
        ),
      );
}
