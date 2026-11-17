import 'player_color.dart';
import 'player_name.dart';

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
    this.defaultAvatarId,
    this.isBot = false,
    this.isLocalSeat = false,
    this.isConnected = true,
  });

  final String playerId;
  final String displayName;
  final PlayerColor color;

  /// Optional custom avatar; absent means use the approved default avatar.
  final Uri? avatarUri;

  /// Stable identifier for the approved default avatar artwork.
  final String? defaultAvatarId;
  final bool isBot;

  /// Local seats do not have an online presence, even when ready to play.
  final bool isLocalSeat;

  /// Network availability for remote seats; not a local match status.
  final bool isConnected;

  /// Display semantics shared by visual badges and accessibility labels.
  String get presenceLabel {
    if (isLocalSeat) {
      return isBot ? 'BOT' : 'LOCAL';
    }
    return isConnected ? 'ONLINE' : 'OFFLINE';
  }

  MatchPlayerProfile copyWith({
    String? displayName,
    Uri? avatarUri,
    String? defaultAvatarId,
    bool? isBot,
    bool? isLocalSeat,
    bool? isConnected,
  }) {
    return MatchPlayerProfile(
      playerId: playerId,
      displayName: displayName ?? this.displayName,
      color: color,
      avatarUri: avatarUri ?? this.avatarUri,
      defaultAvatarId: defaultAvatarId ?? this.defaultAvatarId,
      isBot: isBot ?? this.isBot,
      isLocalSeat: isLocalSeat ?? this.isLocalSeat,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  static List<MatchPlayerProfile> local({
    Set<PlayerColor> aiPlayers = const {},
    Map<PlayerColor, String> names = const {},
  }) {
    return List<MatchPlayerProfile>.unmodifiable(
      PlayerColor.turnOrder.map(
        (color) => MatchPlayerProfile(
          playerId: 'local-${color.name}',
          displayName: aiPlayers.contains(color)
              ? '${color.name.toUpperCase()} Bot'
              : PlayerName.parse(names[color] ?? color.name.toUpperCase()),
          color: color,
          defaultAvatarId: 'approved-${color.name}',
          isBot: aiPlayers.contains(color),
          isLocalSeat: true,
        ),
      ),
    );
  }

  /// Snapshot identity metadata, deliberately separate from authoritative rules.
  Map<String, Object?> toJson() => {
        'playerId': playerId,
        'displayName': displayName,
        'color': color.name,
        'isBot': isBot,
        'isLocalSeat': isLocalSeat,
        'isConnected': isConnected,
        if (defaultAvatarId != null) 'defaultAvatarId': defaultAvatarId,
        if (avatarUri != null) 'avatarUri': avatarUri.toString(),
      };

  factory MatchPlayerProfile.fromJson(Map<String, dynamic> json) {
    if (json['playerId'] is! String ||
        (json['playerId'] as String).trim().isEmpty ||
        json['displayName'] is! String ||
        json['color'] is! String ||
        json['isBot'] is! bool ||
        json['isLocalSeat'] is! bool ||
        json['isConnected'] is! bool ||
        (json['defaultAvatarId'] != null &&
            json['defaultAvatarId'] is! String) ||
        (json['avatarUri'] != null && json['avatarUri'] is! String)) {
      throw const FormatException('Malformed player identity.');
    }
    return MatchPlayerProfile(
      playerId: json['playerId'] as String,
      displayName: PlayerName.parse(json['displayName'] as String),
      color: PlayerColor.values.byName(json['color'] as String),
      isBot: json['isBot'] as bool,
      isLocalSeat: json['isLocalSeat'] as bool,
      isConnected: json['isConnected'] as bool,
      defaultAvatarId: json['defaultAvatarId'] as String?,
      avatarUri: json['avatarUri'] == null
          ? null
          : Uri.parse(json['avatarUri'] as String),
    );
  }

  static List<MatchPlayerProfile> roster(
    List<MatchPlayerProfile> profiles, {
    required Set<PlayerColor> aiPlayers,
  }) {
    if (profiles.length != 4 ||
        profiles.map((p) => p.color).toSet().length != 4 ||
        profiles.map((p) => p.playerId).toSet().length != 4 ||
        profiles.any(
          (p) =>
              p.playerId.trim().isEmpty ||
              PlayerName.errorFor(p.displayName) != null ||
              p.isBot != aiPlayers.contains(p.color),
        )) {
      throw const FormatException(
        'Profiles must uniquely identify all four seats and AI roles.',
      );
    }
    return List<MatchPlayerProfile>.unmodifiable(
      PlayerColor.turnOrder.map(
        (color) {
          final profile =
              profiles.singleWhere((profile) => profile.color == color);
          return profile.copyWith(
            displayName: PlayerName.parse(profile.displayName),
          );
        },
      ),
    );
  }
}
