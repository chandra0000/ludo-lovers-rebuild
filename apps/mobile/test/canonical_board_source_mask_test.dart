import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/approved_artwork_geometry.dart';
import 'package:ludo_lovers/src/features/match/canonical_board_source_mask.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';

void main() {
  test('the canonical mask includes the glass board but excludes baked UI', () {
    const bounds = CanonicalBoardSourceMask.boardClip;
    const stage = ApprovedArtworkGeometry.referenceCanvas;
    expect(stage.contains(bounds.topLeft), isTrue);
    expect(stage.contains(bounds.bottomRight), isTrue);
    expect(bounds.left, closeTo(10, 1));
    expect(bounds.top, closeTo(205, 1));
    expect(bounds.width, closeTo(557, 1));
    expect(bounds.height, closeTo(567, 1));
    // No baked top avatars or decorative bottom die in the board plate.
    expect(bounds.top, greaterThan(200));
    expect(bounds.bottom, lessThan(800));
  });

  testWidgets('masked reference keeps a full-scale source and live controls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MatchScreen(useCanonicalBoardMask: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.byKey(const Key('canonical_board_mask')), findsOneWidget);
    expect(find.byKey(const Key('canonical_board_source')), findsOneWidget);
    expect(find.byKey(const Key('approved_full_artwork')), findsNothing);
    expect(find.byKey(const Key('roll_dice')), findsOneWidget);
    expect(find.byKey(const Key('profile_orange')), findsOneWidget);

    final asset = tester.widget<Image>(
      find.byKey(const Key('canonical_board_source')),
    );
    expect(asset.fit, BoxFit.fill);
    expect(asset.excludeFromSemantics, isTrue);

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('match_screen_capture')),
    );
    expect(boundary.size, const Size(393, 873));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(png, isNotNull);
        expect(rgba, isNotNull);
        final pixels = rgba!.buffer.asUint8List();
        var saturated = 0;
        for (var y = 280; y < 620; y += 8) {
          for (var x = 60; x < 333; x += 8) {
            final i = (y * image.width + x) * 4;
            final red = pixels[i].toInt();
            final green = pixels[i + 1].toInt();
            final blue = pixels[i + 2].toInt();
            final maximum = [red, green, blue].reduce(
              (a, b) => a > b ? a : b,
            );
            final minimum = [red, green, blue].reduce(
              (a, b) => a < b ? a : b,
            );
            if (maximum > 90 && maximum - minimum > 55) saturated++;
          }
        }
        expect(
          saturated,
          greaterThan(30),
          reason: 'Original glass board pixels are not visible in the mask.',
        );
        final output = File('test-artifacts/canonical-board-mask-393x873.png');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(png!.buffer.asUint8List(), flush: true);
      } finally {
        image.dispose();
      }
    });
  });
}
