import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/presentation/glassy_pawn.dart';

void main() {
  testWidgets(
      'capture all brand materials at stack, track, yard and art-review scales',
      (tester) async {
    const colors = [
      Color(0xFFFF8928),
      Color(0xFF33FF28),
      Color(0xFFF428FF),
      Color(0xFF289EFF),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('material_study'),
              child: Container(
                width: 400,
                height: 300,
                color: const Color(0xFF14101F),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final size in [16.0, 27.0, 30.0, 96.0])
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final color in colors)
                            GlassyPawn(color: color, size: size),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('material_study')),
    );
    await tester.runAsync(() async {
      final image = await boundary
          .toImage(pixelRatio: 1)
          .timeout(const Duration(seconds: 10));
      try {
        final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final file =
            File('test-artifacts/acceptance/pawn-material-scale-study.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        expect(image.width, 400);
        expect(image.height, 300);
      } finally {
        image.dispose();
      }
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
