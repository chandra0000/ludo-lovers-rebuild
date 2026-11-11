import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled approved gameplay artwork stays complete and portrait',
      () async {
    final data = await rootBundle.load(
      'assets/images/board/ludo_board_glass.webp',
    );
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    expect(bytes.lengthInBytes, lessThan(300 * 1024));
    expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
    expect(String.fromCharCodes(bytes.skip(8).take(4)), 'WEBP');

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width / frame.image.height, closeTo(9 / 16, 0.001));
    expect(frame.image.width, 810);
    expect(frame.image.height, 1440);
    frame.image.dispose();
    codec.dispose();
  });
}
