import 'package:flutter/material.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/match_player_profile.dart';
import '../../game/domain/player_color.dart';
import '../../game/domain/team_up_policy.dart';

/// Read-only team outcomes and progress from authoritative state.
class TeamProgressPanel extends StatelessWidget {
  const TeamProgressPanel({
    super.key,
    required this.game,
    required this.profiles,
  });
  final LudoGame game;
  final List<MatchPlayerProfile> profiles;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: Row(
              children: [
                for (final team in TeamUpTeam.values) ...[
                  if (team == TeamUpTeam.b) const SizedBox(width: 8),
                  Expanded(child: _team(team)),
                ],
              ],
            ),
          ),
          if (game.scheduledPlayer != game.activePlayer)
            Semantics(
              liveRegion: true,
              child: Text(
                '${game.scheduledPlayer.name.toUpperCase()} → ${game.activePlayer.name.toUpperCase()}',
                key: const Key('team_transferred_turn'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFD36B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      );

  Widget _team(TeamUpTeam team) {
    final members = PlayerColor.turnOrder
        .where((c) => TeamUpPolicy.teamFor(c) == team)
        .toList();
    final names = members
        .map((c) => profiles.singleWhere((p) => p.color == c).displayName)
        .join(' + ');
    final finished = game.players
        .where((p) => members.contains(p.color))
        .expand((p) => p.pawnProgress)
        .where((v) => v == finishProgress)
        .length;
    final capacity = game.players
        .where((p) => members.contains(p.color))
        .fold(0, (total, p) => total + p.pawnProgress.length);
    final label = 'TEAM ${team.name.toUpperCase()} · $finished/$capacity';
    return Semantics(
      label: '$label pawns home. $names',
      child: Container(
        key: Key('team_progress_${team.name}'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1728),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: TeamUpPolicy.teamFor(game.activePlayer) == team
                ? const Color(0xFFFFD36B)
                : const Color(0xFF65536E),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFD36B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              names,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
