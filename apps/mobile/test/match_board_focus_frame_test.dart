import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_board_focus_frame.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';

void main() {
  testWidgets('board frame is visible without changing the board position', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);

    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    await tester.pump();

    expect(find.byKey(const Key('match_board_focus_frame')), findsOneWidget);
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    expect(find.byKey(const Key('turn_status')), findsOneWidget);

    final board = tester.getRect(find.byKey(const Key('board_artwork')));
    final canvas = tester.getRect(
      find.byKey(const Key('match_board_focus_frame')),
    );
    expect(canvas.contains(board.topLeft), isTrue);
    expect(canvas.contains(board.bottomRight), isTrue);
  });

  testWidgets('focus halo is pixel-transparent throughout board interior', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(576, 1024);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: Key('halo_pixel_capture'),
          child: SizedBox(
            width: 576,
            height: 1024,
            child: Stack(children: [MatchBoardFocusFrame()]),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('halo_pixel_capture')),
    );
    final image = await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1),
    );
    expect(image, isNotNull);
    final capturedImage = image!;
    addTearDown(capturedImage.dispose);
    final byteData = await tester.runAsync(
      () => capturedImage.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    expect(byteData, isNotNull);
    final bytes = byteData!.buffer.asUint8List();
    final board = Rect.fromLTWH(
      MatchBoardFocusFrame.artworkRect.left,
      MatchBoardFocusFrame.artworkRect.top,
      MatchBoardFocusFrame.artworkRect.width,
      MatchBoardFocusFrame.artworkRect.height,
    );
    // Every pixel strictly inside the image is untouched, not merely its
    // central pixels. This catches inward shadows and border regressions.
    for (var y = board.top.ceil(); y < board.bottom.floor(); y++) {
      for (var x = board.left.ceil(); x < board.right.floor(); x++) {
        if (bytes[(y * capturedImage.width + x) * 4 + 3] != 0) {
          fail('Halo modified board-interior pixel ($x,$y)');
        }
      }
    }
  });
}
