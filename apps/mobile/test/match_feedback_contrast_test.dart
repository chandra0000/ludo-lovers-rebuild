import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/app.dart';

void main() {
  testWidgets(
      'production feedback snackbar text contrasts with its dark surface',
      (tester) async {
    final messenger = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          final app = const LudoLoversApp().build(context) as MaterialApp;
          return MaterialApp(
            theme: app.theme,
            scaffoldMessengerKey: messenger,
            home: const Scaffold(body: SizedBox.expand()),
          );
        },
      ),
    );
    messenger.currentState!.showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF211A0D),
        content: Text('CAPTURE — EXTRA TURN'),
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('CAPTURE — EXTRA TURN'),
    );
    final foreground = paragraph.text.style!.color!;
    const background = Color(0xFF211A0D);
    final light = foreground.computeLuminance();
    final dark = background.computeLuminance();
    final ratio = light >= dark
        ? (light + .05) / (dark + .05)
        : (dark + .05) / (light + .05);
    expect(ratio, greaterThanOrEqualTo(4.5));
    expect(tester.takeException(), isNull);
  });
}
