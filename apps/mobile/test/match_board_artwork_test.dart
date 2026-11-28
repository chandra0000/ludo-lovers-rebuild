import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_board_artwork.dart';

void main() {
  testWidgets(
    'board overlays become visible and interactive with the artwork',
    (tester) async {
      final image = _DelayedImage();
      const pawn = Key('pawn');
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MatchBoardArtwork(
            image: image,
            overlays: [
              Positioned(
                left: 100,
                top: 240,
                child: GestureDetector(
                  key: pawn,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox(width: 48, height: 48),
                ),
              ),
            ],
          ),
        ),
      );
      final visibleOverlay = find.descendant(
        of: find.byType(MatchBoardArtwork),
        matching: find.byType(Visibility),
      );
      expect(find.text('Preparing the board…'), findsOneWidget);
      expect(tester.widget<Visibility>(visibleOverlay).visible, isFalse);
      expect(find.byKey(pawn).hitTestable(), findsNothing);

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
      image.frame.complete(ImageInfo(image: bitmap!));
      await tester.pump();

      expect(find.text('Preparing the board…'), findsNothing);
      expect(tester.widget<Visibility>(visibleOverlay).visible, isTrue);
      expect(find.byKey(pawn).hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(pawn));
      expect(taps, 1);
    },
  );

  testWidgets('board artwork remains a dedicated immutable render layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: MatchBoardArtwork(),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
    final artwork = tester.widget<Image>(
      find.ancestor(
        of: find.byKey(const Key('board_artwork')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (artwork.image as AssetImage).assetName,
      MatchBoardArtwork.assetPath,
    );
    expect(
      MatchBoardArtwork.assetPath,
      'assets/images/board/extracted/board_exact.webp',
    );
  });
}

class _DelayedImage extends ImageProvider<_DelayedImage> {
  final frame = Completer<ImageInfo>();

  @override
  Future<_DelayedImage> obtainKey(ImageConfiguration configuration) async =>
      this;

  @override
  ImageStreamCompleter loadImage(
    _DelayedImage key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(frame.future);
}
