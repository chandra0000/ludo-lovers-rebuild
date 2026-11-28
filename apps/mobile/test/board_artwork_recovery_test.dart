import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:ludo_lovers/src/theme/app_typography.dart';
import 'package:ludo_lovers/src/features/match/game_board_scaffold.dart';
import 'package:ludo_lovers/src/features/match/match_board_artwork.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'support/capture_artifact.dart';
import 'support/load_sdk_fonts.dart';

class _RecoveringImage extends ImageProvider<_RecoveringImage> {
  final frames = [Completer<ImageInfo>(), Completer<ImageInfo>()];
  Completer<bool>? eviction;
  var loads = 0;
  final error = StateError('Injected image decode failure');
  @override
  Future<_RecoveringImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    _RecoveringImage key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(frames[loads++].future);
  @override
  Future<bool> evict({
    ImageCache? cache,
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) async {
    if (eviction != null) await eviction!.future;
    return super.evict(cache: cache, configuration: configuration);
  }
}

Future<void> _mount(
  WidgetTester tester,
  _RecoveringImage image, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        final theme =
            (const LudoLoversApp().build(context) as MaterialApp).theme;
        return MaterialApp(
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: SafeArea(child: child!),
          ),
          home: Scaffold(
            body: RepaintBoundary(
              key: const Key('recovery_capture'),
              child: GameBoardScaffold(
                game: LudoGame.initial(),
                profiles: MatchPlayerProfile.local(),
                onExit: () {},
                dice: const SizedBox(width: 64, height: 64),
                utilities: const SizedBox(height: 48),
                status:
                    const Text('Board recovery', style: AppTypography.status),
                reaction: const SizedBox.shrink(),
                boardBuilder: (_, scale) => MatchBoardArtwork(
                  image: image,
                  canvasScale: scale,
                  overlays: [
                    Positioned(
                      left: 100,
                      top: 400,
                      child: GestureDetector(
                        key: const Key('recoverable_pawn'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: const SizedBox(width: 48, height: 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
  image.frames.first.completeError(image.error);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSdkFonts);
  for (final textScale in [1.0, 1.3, 1.5, 2.0]) {
    for (final size in const [
      Size(320, 640),
      Size(360, 800),
      Size(393, 873),
      Size(430, 932),
    ]) {
      testWidgets(
          'retry recovers decoded board at $size with ${textScale}x text',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.resetPadding);
        final image = _RecoveringImage();
        await _mount(tester, image, textScale: textScale);
        expect(tester.takeException(), isNull);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(MatchBoardArtwork)),
          ).scale(10),
          10 * textScale,
        );
        final button = find.byKey(const Key('retry_board_artwork'));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(button.hitTestable(), findsOneWidget);
        final rect = tester.getRect(button);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        final visibleRect = rect
            .intersect(tester.getRect(find.byKey(const Key('board_stage'))));
        expect(visibleRect.width, greaterThanOrEqualTo(48));
        expect(visibleRect.height, greaterThanOrEqualTo(48));
        expect(
          find.byKey(const Key('recoverable_pawn')).hitTestable(),
          findsNothing,
        );
        await captureArtifact(
          tester,
          'board-error-${size.width.toInt()}x${size.height.toInt()}-${textScale}x',
          key: const Key('recovery_capture'),
          expectedImageErrors: [image.error],
        );
        final retry = tester.widget<FilledButton>(button).onPressed!;
        retry();
        retry();
        await tester.pump();
        await tester.pump();
        expect(
          image.loads,
          2,
          reason: 'One replacement stream for rapid retry input',
        );
        expect(
          find.byKey(const Key('recoverable_pawn')).hitTestable(),
          findsNothing,
        );
        final bitmap = await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          Canvas(recorder).drawColor(Colors.orange, BlendMode.src);
          final picture = recorder.endRecording();
          try {
            return await picture.toImage(1, 1);
          } finally {
            picture.dispose();
          }
        });
        image.frames.last.complete(ImageInfo(image: bitmap!));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('retry_board_artwork')), findsNothing);
        expect(
          find.byKey(const Key('recoverable_pawn')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
  testWidgets('eviction completing after disposal has no late setState',
      (tester) async {
    final image = _RecoveringImage();
    await _mount(tester, image);
    image.eviction = Completer<bool>();
    await tester.tap(find.byKey(const Key('retry_board_artwork')));
    await tester.pumpWidget(const SizedBox.shrink());
    image.eviction!.complete(true);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
