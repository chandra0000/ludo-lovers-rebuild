import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/presentation/destination_preview_painter.dart';

void main() {
  testWidgets('destination preview painter renders a target without errors',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            key: Key('preview_canvas'),
            size: Size(200, 200),
            painter: DestinationPreviewPainter(
              targetCenter: Offset(100, 100),
              cellSize: 36,
              playerColor: Color(0xFFFF8928),
              previewType: DestinationPreviewType.capture,
              animationProgress: .25,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('preview_canvas')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
