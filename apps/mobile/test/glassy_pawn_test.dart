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
    expect(find.byType(CustomPaint), findsOneWidget);
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
}
