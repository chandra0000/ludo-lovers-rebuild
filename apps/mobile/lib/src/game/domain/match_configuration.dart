import 'player_color.dart';

/// Mode identity is separate from the immutable movement/capture rule profile.
enum MatchMode { compatibility, classic, quick, teamUp }

class MatchConfiguration {
  const MatchConfiguration._(this.mode, this.version, this.activePlayers);

  static const compatibility = MatchConfiguration._(
    MatchMode.compatibility,
    1,
    PlayerColor.turnOrder,
  );

  factory MatchConfiguration.local(MatchMode mode, {int playerCount = 4}) {
    if (playerCount < 2 ||
        playerCount > 4 ||
        ((mode == MatchMode.compatibility || mode == MatchMode.teamUp) &&
            playerCount != 4)) {
      throw ArgumentError.value(
        playerCount,
        'playerCount',
        'Unsupported seat configuration',
      );
    }
    return MatchConfiguration._(
      mode,
      1,
      List.unmodifiable(
        switch (playerCount) {
          2 => [PlayerColor.orange, PlayerColor.magenta],
          3 => [PlayerColor.orange, PlayerColor.green, PlayerColor.magenta],
          _ => PlayerColor.turnOrder,
        },
      ),
    );
  }

  final MatchMode mode;
  final int version;
  final List<PlayerColor> activePlayers;
  bool get isTeamUp => mode == MatchMode.teamUp;
  int get finishTarget => mode == MatchMode.quick ? 2 : 4;
  String get id => switch (mode) {
        MatchMode.compatibility => 'local-current',
        MatchMode.classic => 'classic',
        MatchMode.quick => 'quick',
        MatchMode.teamUp => 'team-up',
      };

  Map<String, Object> toJson() => {
        'id': id,
        'version': version,
        'activePlayers': activePlayers.map((c) => c.name).toList(),
      };

  factory MatchConfiguration.fromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['activePlayers'] is! List) {
      throw const FormatException('Unsupported match configuration');
    }
    final mode = switch (value['id']) {
      'local-current' => MatchMode.compatibility,
      'classic' => MatchMode.classic,
      'quick' => MatchMode.quick,
      'team-up' => MatchMode.teamUp,
      _ => throw const FormatException('Unknown match mode'),
    };
    final seats = value['activePlayers'] as List;
    try {
      final configuration =
          MatchConfiguration.local(mode, playerCount: seats.length);
      if (seats.join(',') !=
          configuration.activePlayers.map((c) => c.name).join(',')) {
        throw const FormatException('Noncanonical active seats');
      }
      return configuration;
    } on ArgumentError {
      throw const FormatException('Invalid active seats');
    }
  }
}
