import 'player_color.dart';

/// Presentation identity for a match seat, independent of Ludo rules.
///
/// [playerId] is stable within a match. Online account identifiers can be
/// mapped to it later without changing pawn movement or turn order.
class MatchPlayerProfile {
  const MatchPlayerProfile({
    required this.playerId,
    required this.displayName,
    required this.color,
    this.avatarUri,
    this.isBot = false,
    this.isConnected = true,
  });

  final String playerId;
  final String displayName;
  final PlayerColor color;
  final Uri? avatarUri;
  final bool isBot;
  final bool isConnected;

  MatchPlayerProfile copyWith({
    String? displayName,
    Uri? avatarUri,
    bool? isBot,
    bool? isConnected,
  }) {
    return MatchPlayerProfile(
      playerId: playerId,
      displayName: displayName ?? this.displayName,
      color: color,
      avatarUri: avatarUri ?? this.avatarUri,
      isBot: isBot ?? this.isBot,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  static List<MatchPlayerProfile> local({
    Set<PlayerColor> aiPlayers = const {},
  }) {
    return List<MatchPlayerProfile>.unmodifiable(
      PlayerColor.turnOrder.map(
        (color) => MatchPlayerProfile(
          playerId: 'local-${color.name}',
          displayName: aiPlayers.contains(color)
              ? '${color.name.toUpperCase()} Bot'
              : color.name.toUpperCase(),
          color: color,
          isBot: aiPlayers.contains(color),
        ),
      ),
    );
  }
}
