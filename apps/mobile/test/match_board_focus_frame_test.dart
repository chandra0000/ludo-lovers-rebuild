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
    final image = await tester.runAsync(\n      () => boundary.toImage(pixelRatio: 0.25),\n    );\n    expect(image, isNotNull);
    addTearDown(image!.dispose);
    final byteData = await tester.runAsync(\n      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),\n    );
    expect(byteData, isNotNull);
    final bytes = byteData!.buffer.asUint8List();
    final board = Rect.fromLTWH(\n      MatchBoardFocusFrame.artworkRect.left * 0.25,\n      MatchBoardFocusFrame.artworkRect.top * 0.25,\n      MatchBoardFocusFrame.artworkRect.width * 0.25,\n      MatchBoardFocusFrame.artworkRect.height * 0.25,\n    );
    // Every pixel strictly inside the image is untouched, not merely its
    // central pixels. This catches inward shadows and border regressions.
    for (var y = board.top.ceil(); y < board.bottom.floor(); y++) {
      for (var x = board.left.ceil(); x < board.right.floor(); x++) {
        if (bytes[(y * image.width + x) * 4 + 3] != 0) {
          fail('Halo modified board-interior pixel ($x,$y)');
        }
      }
    }
  });

  testWidgets('match instructions and pawn chooser are touch-accessible', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);

    await tester.pumpWidget(
      MaterialApp(home: MatchScreen(rollDice: () => 6)),
    );
    await tester.pump();
    expect(find.text('Roll dice'), findsOneWidget);

    final exit = tester.getSize(find.byKey(const Key('exit_match')));
    expect(exit.width, greaterThanOrEqualTo(48));
    expect(exit.height, greaterThanOrEqualTo(48));

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accessible_pawn_chooser')), findsOneWidget);
    final chooser = tester.getSize(
      find.byKey(const Key('accessible_pawn_chooser')),
    );
    expect(chooser.width, greaterThanOrEqualTo(48));
    expect(chooser.height, greaterThanOrEqualTo(48));

    await tester.tap(find.byKey(const Key('accessible_pawn_chooser')));
    await tester.pumpAndSettle();
    expect(find.text('Pawn 1'), findsOneWidget);
    await tester.tap(find.text('Pawn 1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accessible_pawn_chooser')), findsNothing);
  });
}
