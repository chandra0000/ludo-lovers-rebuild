import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Capture real Flutter paint with complete real-async I/O and explicit cleanup.
/// Negative image fixtures may declare exact injected errors; ordinary captures
/// still require an empty error list. No unexpected decode error is ignored.
Future<void> captureArtifact(
  WidgetTester tester,
  String name, {
  Key key = const Key('match_screen_capture'),
  List<Object> expectedImageErrors = const [],
}) async {
  final errors = <Object>[];
  final context = tester.element(find.byType(MaterialApp));
  final providers =
      tester.widgetList<Image>(find.byType(Image)).map((i) => i.image).toSet();
  await tester.runAsync(
    () => Future.wait(
      providers.map(
        (p) => precacheImage(
          p,
          context,
          onError: (error, stack) => errors.add(error),
        ),
      ),
    ).timeout(const Duration(seconds: 10)),
  );
  expect(errors, orderedEquals(expectedImageErrors));
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump();
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary
        .toImage(pixelRatio: 1)
        .timeout(const Duration(seconds: 10));
    try {
      final bytes = (await image
          .toByteData(format: ui.ImageByteFormat.png)
          .timeout(const Duration(seconds: 10)))!;
      final file = File('test-artifacts/acceptance/$name.png');
      await file.parent
          .create(recursive: true)
          .timeout(const Duration(seconds: 10));
      await file
          .writeAsBytes(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          )
          .timeout(const Duration(seconds: 10));
      final encoded =
          await file.readAsBytes().timeout(const Duration(seconds: 10));
      final codec = await ui
          .instantiateImageCodec(encoded)
          .timeout(const Duration(seconds: 10));
      try {
        final frame =
            await codec.getNextFrame().timeout(const Duration(seconds: 10));
        try {
          expect(frame.image.width, image.width);
          expect(frame.image.height, image.height);
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } finally {
      image.dispose();
    }
  });
}
