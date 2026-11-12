import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_board_artwork.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('approved board asset decodes and contains visible artwork', () async {
    final data = await rootBundle.load(MatchBoardArtwork.assetPath);
    expect(data.lengthInBytes, greaterThan(10000),
        reason: 'The approved board file must not be a placeholder.');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        expect(image.width, greaterThan(200));
        expect(image.height, greaterThan(200));
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        expect(bytes, isNotNull);
        final rgba = bytes!.buffer.asUint8List();
        var visible = 0;
        var colorful = 0;
        // Sample a deterministic grid instead of decoding a second image.
        final stride = image.width * 4;
        final xStep = image.width ~/ 24;
        final yStep = image.height ~/ 24;
        for (var y = 0; y < image.height; y += yStep) {
          for (var x = 0; x < image.width; x += xStep) {
            final i = y * stride + x * 4;
            final r = rgba[i];
            final g = rgba[i + 1];
            final b = rgba[i + 2];
            final a = rgba[i + 3];
            if (a > 128) {
              visible++;
              if (r > 70 || g > 70 || b > 70) colorful++;
            }
          }
        }
        expect(visible, greaterThan(100),
            reason: 'Board artwork is nearly transparent.');
        expect(colorful, greaterThan(30),
            reason: 'Board artwork is unexpectedly dark or empty.');
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  });
}
