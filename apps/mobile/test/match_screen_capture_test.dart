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
        final output = File('test-artifacts/match-screen-393x873.png');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      } finally {
        image.dispose();
      }
    });
  });
}
