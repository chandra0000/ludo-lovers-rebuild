import 'ludo_game.dart';
import 'match_configuration.dart';

enum ModeAvailability { available, internalPreview, comingSoon }

class ModeDefinition {
  const ModeDefinition({
    required this.mode,
    required this.name,
    required this.description,
    required this.playerCounts,
    required this.availability,
  });
  final MatchMode mode;
  final String name;
  final String description;
  final List<int> playerCounts;
  final ModeAvailability availability;
  bool get supportsOffline => true;
  bool get supportsOnline => false;
  int get version => 1;
}

/// Public availability is not inferred from the presence of engine code.
class ModeRegistry {
  static const internalBuild =
      bool.fromEnvironment('LUDO_ENABLE_UNRELEASED_MODES');
  static const definitions = [
    ModeDefinition(
      mode: MatchMode.compatibility,
      name: 'Local game',
      description: 'Four seats · current compatibility rules',
      playerCounts: [4],
      availability: ModeAvailability.available,
    ),
    ModeDefinition(
      mode: MatchMode.classic,
      name: 'Classic',
      description: 'Exact finish · protected stacks · third-six penalty',
      playerCounts: [2, 3, 4],
      availability: ModeAvailability.internalPreview,
    ),
    ModeDefinition(
      mode: MatchMode.quick,
      name: 'Quick',
      description: 'First to finish any two pawns · Classic movement rules',
      playerCounts: [2, 3, 4],
      availability: ModeAvailability.comingSoon,
    ),
    ModeDefinition(
      mode: MatchMode.teamUp,
      name: 'Team Up',
      description: 'Orange + Magenta versus Green + Blue',
      playerCounts: [4],
      availability: ModeAvailability.comingSoon,
    ),
  ];

  static ModeDefinition definition(MatchMode mode) =>
      definitions.singleWhere((d) => d.mode == mode);
  static bool canPlay(MatchMode mode, {bool allowInternal = internalBuild}) =>
      definition(mode).availability == ModeAvailability.available ||
      (allowInternal &&
          definition(mode).availability == ModeAvailability.internalPreview);

  static LudoGame create(
    MatchMode mode, {
    int playerCount = 4,
    bool allowInternal = internalBuild,
  }) {
    if (!canPlay(mode, allowInternal: allowInternal)) {
      throw StateError('Mode has not passed its public release gates');
    }
    return LudoGame.initial(
      ruleProfile: mode == MatchMode.classic
          ? LudoRuleProfile.classicV1
          : LudoRuleProfile.currentV1,
      configuration: MatchConfiguration.local(mode, playerCount: playerCount),
    );
  }
}
