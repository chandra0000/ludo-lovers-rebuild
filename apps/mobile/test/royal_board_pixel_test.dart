import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/game_board_scaffold.dart';
import 'package:ludo_lovers/src/features/match/royal_backdrop.dart';
import 'package:ludo_lovers/src/features/match/premium_match_layout.dart';
import 'package:ludo_lovers/src/features/match/match_board_artwork.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';

void main() {
  testWidgets(
      'unified scaffold preserves every canonical board pixel at equal scale',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<Uint8List> capture(bool unified) async {
      final child = unified
          ? GameBoardScaffold(
              game: LudoGame.initial(),
              profiles: MatchPlayerProfile.local(),
              onExit: () {},
              dice: const SizedBox(),
              utilities: const SizedBox(),
              status: const SizedBox(),
              reaction: const SizedBox(),
              boardBuilder: (_, __) => const MatchBoardArtwork(),
            )
          : PremiumMatchLayout(
              profiles: const SizedBox(),
              controls: const SizedBox(),
              onExit: () {},
              reaction: const SizedBox(),
              boardBuilder: (_, __) => const MatchBoardArtwork(),
            );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: unified ? RoyalBackdrop(child: child) : child),
        ),
      );
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(MatchBoardArtwork.assetPath),
          context,
        ).timeout(const Duration(seconds: 10)),
      );
      await tester.pump();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('match_canvas_capture')),
      );
      final result = await tester.runAsync(() async {
        final image =
            await boundary.toImage().timeout(const Duration(seconds: 10));
        try {
          final bytes = (await image
              .toByteData(format: ui.ImageByteFormat.rawRgba)
              .timeout(const Duration(seconds: 10)))!;
          return Uint8List.fromList(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        } finally {
          image.dispose();
        }
      });
      return result!;
    }

    final before = await capture(false);
    final after = await capture(true);
    expect(
      after,
      orderedEquals(before),
      reason:
          'No change to the board registration, scale, asset or painted interior',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'composited board pixels never change when a bottom profile gains its glow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    Future<Uint8List> boardPixels(PlayerColor active) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('composited_capture'),
          child: MaterialApp(
            home: Scaffold(
              body: RoyalBackdrop(
                child: SafeArea(
                  child: GameBoardScaffold(
                    game: LudoGame.fromProgress(
                      activePlayer: active,
                      pawnProgress: const {},
                    ),
                    profiles: MatchPlayerProfile.local(),
                    onExit: () {},
                    dice: const SizedBox(),
                    utilities: const SizedBox(),
                    status: const SizedBox(),
                    reaction: const SizedBox(),
                    boardBuilder: (_, __) => const MatchBoardArtwork(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(MatchBoardArtwork.assetPath),
          tester.element(find.byType(MaterialApp)),
        ).timeout(const Duration(seconds: 10)),
      );
      await tester.pumpAndSettle();
      final board = tester.getRect(find.byKey(const Key('board_stage')));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('composited_capture')),
      );
      return (await tester.runAsync(() async {
        final image =
            await boundary.toImage().timeout(const Duration(seconds: 10));
        try {
          final raw = (await image
              .toByteData(format: ui.ImageByteFormat.rawRgba)
              .timeout(const Duration(seconds: 10)))!;
          final bytes =
              raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes);
          final crop = BytesBuilder();
          for (var y = board.top.ceil(); y < board.bottom.floor(); y++) {
            crop.add(
              bytes.sublist(
                (y * image.width + board.left.ceil()) * 4,
                (y * image.width + board.right.floor()) * 4,
              ),
            );
          }
          return crop.takeBytes();
        } finally {
          image.dispose();
        }
      }))!;
    }

    final orange = await boardPixels(PlayerColor.orange);
    final blue = await boardPixels(PlayerColor.blue);
    expect(
      blue,
      orderedEquals(orange),
      reason: 'HUD shadow, ornaments and reactions cannot repaint the board',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
