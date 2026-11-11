import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';

void main() {
  Future<void> pumpMatch(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('board and pawn canvas share one aspect-preserving viewport', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in <Size>[
      const Size(393, 873),
      const Size(412, 915),
    ]) {
      await pumpMatch(tester, size);
      final canvas = tester.getSize(find.byKey(const Key('match_canvas')));
      final artwork = find.byKey(const Key('board_artwork'));
      expect(artwork, findsOneWidget);
      expect(canvas.width, lessThanOrEqualTo(size.width));
      expect(canvas.height, lessThanOrEqualTo(size.height));
      expect(
        canvas.width / canvas.height,
        closeTo(BoardGeometry.canvasWidth / BoardGeometry.canvasHeight, 0.001),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('background and resume preserve the current match viewport', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpMatch(tester, const Size(393, 873));
    final canvas = tester.getSize(find.byKey(const Key('match_canvas')));

    await tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    await tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    await tester.pump();
    expect(find.byKey(const Key('match_canvas')), findsOneWidget);

    await tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pump();
    expect(tester.getSize(find.byKey(const Key('match_canvas'))), canvas);
    expect(find.byKey(const Key('turn_status')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
