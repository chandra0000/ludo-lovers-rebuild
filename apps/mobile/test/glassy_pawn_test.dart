import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/presentation/glassy_pawn.dart';

void main() {
  testWidgets('renders a glass-finish cone pawn with semantic wrapper',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Semantics(
              label: 'Green pawn 1',
              child: const GlassyPawn(
                color: Color(0xFF33FF28),
                isCurrentPlayer: true,
                isMovable: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GlassyPawn), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GlassyPawn),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(GlassyPawn)), const Size(30, 35.4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports compact size for pawns sharing a cell', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassyPawn(
              color: Color(0xFF289EFF),
              size: 16,
              isCurrentPlayer: false,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(GlassyPawn)), const Size(16, 18.88));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders every branded pawn color with stable dimensions',
      (tester) async {
    const colors = [
      Color(0xFFFF8928),
      Color(0xFF33FF28),
      Color(0xFF289EFF),
      Color(0xFFF428FF),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              for (final color in colors)
                GlassyPawn(color: color, size: 24, isMovable: true),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(GlassyPawn), findsNWidgets(4));
    for (final pawn in tester.widgetList<GlassyPawn>(find.byType(GlassyPawn))) {
      expect(colors, contains(pawn.color));
    }
    expect(tester.takeException(), isNull);
  });
}
