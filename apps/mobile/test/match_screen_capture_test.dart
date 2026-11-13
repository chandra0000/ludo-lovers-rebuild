import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';

void main() {
  testWidgets('captures the complete 393x873 match viewport', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);

    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    await tester.pump(const Duration(milliseconds: 250));
    // Asset decode is asynchronous; pump again after the first frame so the
    // capture checks actual board pixels rather than a loading placeholder.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('match_screen_capture')),
    );
    expect(boundary.size, const Size(393, 873));

    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        expect(image.width, 393);
        expect(image.height, 873);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(bytes, isNotNull);
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(rgba, isNotNull);
        final pixels = rgba!.buffer.asUint8List();
        var saturated = 0;
        var bright = 0;
        // Sample only the central board, excluding the top/bottom controls.
        // A missing image produces the nearly-black background seen on device.
        for (var y = 280; y < 620; y += 8) {
          for (var x = 60; x < 333; x += 8) {
            final i = (y * image.width + x) * 4;
            final r = pixels[i].toInt();
            final g = pixels[i + 1].toInt();
            final b = pixels[i + 2].toInt();
            final maximum = [r, g, b].reduce((a, b) => a > b ? a : b);
            final minimum = [r, g, b].reduce((a, b) => a < b ? a : b);
            if (maximum > 95) bright++;
            if (maximum - minimum > 55 && maximum > 90) saturated++;
          }
        }
        expect(
          bright,
          greaterThan(80),
          reason: 'The composed match screen is missing visible board artwork.',
        );
        expect(
          saturated,
          greaterThan(30),
          reason: 'The composed board has lost its approved colored cells.',
        );
        final output = File('test-artifacts/match-screen-393x873.png');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      } finally {
        image.dispose();
      }
    });
  });
}
