import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';

void main() {
  testWidgets('extra portrait height contains branded rails and all controls', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);

    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    await tester.pump();

    expect(find.byKey(const Key('match_top_rail')), findsOneWidget);
    expect(find.byKey(const Key('match_bottom_rail')), findsOneWidget);
    expect(find.byKey(const Key('match_brand_mark')), findsOneWidget);
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    expect(find.byKey(const Key('animated_dice')), findsOneWidget);
    expect(find.byKey(const Key('six_face_dice_cube')), findsOneWidget);
    expect(find.byKey(const Key('chat_button')), findsOneWidget);
    expect(find.byKey(const Key('quick_reactions_button')), findsOneWidget);
    expect(find.byKey(const Key('more_button')), findsOneWidget);
  });

  testWidgets('footer actions retain large tap regions on compact phones', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);

    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    await tester.pump();

    for (final name in <String>[
      'chat_button',
      'quick_reactions_button',
      'more_button',
    ]) {
      final rect = tester.getRect(find.byKey(Key(name)));
      expect(rect.width, greaterThanOrEqualTo(48), reason: name);
      expect(rect.height, greaterThanOrEqualTo(48), reason: name);
    }
  });

  testWidgets('reaction picker shows local choices and displays a toast', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);

    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quick_reactions_button')));
    await tester.pumpAndSettle();

    expect(find.text('Emoji reactions · On this device'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick_reaction_👏')));
    await tester.pump();
    expect(find.byKey(const Key('local_reaction_toast')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('local_reaction_toast')), findsNothing);
  });
}
