import 'package:flutter/material.dart';

import '../../game/domain/match_player_profile.dart';
import '../../game/domain/player_color.dart';
import '../../game/presentation/player_color_theme.dart';
import 'approved_artwork_geometry.dart';

/// Replaces the reference's baked name/connection labels with live information.
/// The baked portraits remain reference-only until a clean static plate is
/// approved, so this preview must not be enabled for public release.
class ApprovedArtworkProfilesLayer extends StatelessWidget {
  const ApprovedArtworkProfilesLayer({
    super.key,
    required this.profiles,
    required this.activeColor,
  });

  final List<MatchPlayerProfile> profiles;
  final PlayerColor activeColor;

  Rect _labelFor(PlayerColor color) => switch (color) {
        PlayerColor.orange => ApprovedArtworkGeometry.orangeLabel,
        PlayerColor.green => ApprovedArtworkGeometry.greenLabel,
        PlayerColor.blue => ApprovedArtworkGeometry.blueLabel,
        PlayerColor.magenta => ApprovedArtworkGeometry.magentaLabel,
      };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final profile in profiles)
          Positioned.fromRect(
            rect: _labelFor(profile.color),
            child: Semantics(
              label: '${profile.displayName}, ${profile.color.name}, '
                  '${profile.isConnected ? 'connected' : 'disconnected'}'
                  '${activeColor == profile.color ? ', current turn' : ''}',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: profile.color == activeColor
                        ? const Color(0xFFFFD36B)
                        : const Color(0xFF705527),
                    width: profile.color == activeColor ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profile.displayName,
                      key: Key('profile_name_${profile.color.name}'),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFFFFE4A4),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      profile.isBot
                          ? 'BOT'
                          : profile.isConnected
                              ? 'ONLINE'
                              : 'OFFLINE',
                      style: TextStyle(
                        color: profile.color.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A live, non-interactive status label in the reference's own gold frame.
class ApprovedArtworkTurnOverlay extends StatelessWidget {
  const ApprovedArtworkTurnOverlay({
    super.key,
    required this.statusText,
    required this.activePlayer,
  });

  final String statusText;
  final PlayerColor activePlayer;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: ApprovedArtworkGeometry.turnStatusRect,
      child: IgnorePointer(
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF090707),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFD36B),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Text(
                statusText,
                key: const Key('turn_status'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: activePlayer.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Transparent gesture and semantics layers preserve the approved Chat and
/// More icons instead of painting duplicate buttons over the source art.
class ApprovedArtworkActionsLayer extends StatelessWidget {
  const ApprovedArtworkActionsLayer({
    super.key,
    required this.onChat,
    required this.onMore,
  });

  final VoidCallback onChat;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fromRect(
          rect: ApprovedArtworkGeometry.chatTouchRect,
          child: Semantics(
            button: true,
            label: 'Chat',
            hint: 'Open local chat and emoji reactions.',
            child: GestureDetector(
              key: const Key('chat_button'),
              behavior: HitTestBehavior.opaque,
              onTap: onChat,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: ApprovedArtworkGeometry.moreTouchRect,
          child: Semantics(
            button: true,
            label: 'More options',
            child: GestureDetector(
              key: const Key('more_button'),
              behavior: HitTestBehavior.opaque,
              onTap: onMore,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}
