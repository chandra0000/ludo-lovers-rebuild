import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

import 'support/load_sdk_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSdkFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final configuration in const [
    (size: Size(320, 568), dpr: 2.0, top: 20.0, bottom: 0.0),
    (size: Size(375, 667), dpr: 2.0, top: 20.0, bottom: 0.0),
    (size: Size(393, 873), dpr: 3.0, top: 59.0, bottom: 34.0),
    (size: Size(440, 956), dpr: 3.0, top: 62.0, bottom: 34.0),
    (size: Size(360, 780), dpr: 2.75, top: 32.0, bottom: 24.0),
    (size: Size(600, 1024), dpr: 2.0, top: 24.0, bottom: 24.0),
  ]) {
    responsiveTest(
      configuration.size,
      configuration.dpr,
      configuration.top,
      configuration.bottom,
      extended: true,
    );
  }
  for (final viewport in const [
    Size(360, 800),
    Size(393, 873),
    Size(430, 932),
    Size(320, 640),
  ]) {
    responsiveTest(viewport, 1, 24, 24);
  }
}

void responsiveTest(
  Size viewport,
  double dpr,
  double top,
  double bottom, {
  bool extended = false,
}) {
  testWidgets(
    'match presents board, seats, dice, chat and reactions at $viewport DPR $dpr insets $top/$bottom',
    (tester) async {
      void stage(String name) => debugPrint('viewport $viewport: $name');
      addTearDown(() async {
        stage('cleanup');
        try {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          expect(tester.takeException(), isNull);
        } finally {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetViewPadding();
          tester.view.resetPadding();
        }
        stage('cleanup complete');
      });
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = viewport * dpr;
      // Exercise a top status/notch inset and bottom gesture area.
      tester.view.viewPadding = FakeViewPadding(
        top: top * dpr,
        bottom: bottom * dpr,
      );

      tester.view.padding = FakeViewPadding(
        top: top * dpr,
        bottom: bottom * dpr,
      );

      stage('initialize');
      await tester.pumpWidget(
        MaterialApp(
          home: MatchScreen(
            profiles: MatchPlayerProfile.local(
              names: {
                PlayerColor.orange: 'Aarav',
                PlayerColor.green: 'Zoë',
                PlayerColor.magenta: 'Maya',
                PlayerColor.blue: 'Noah',
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Resolve the actual providers (including resized avatars), with a
      // real deadline instead of a sleep or unbounded pumpAndSettle.
      stage('asset decode');
      final context = tester.element(find.byType(MatchScreen));
      final imageErrors = <Object>[];
      final providers = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => image.image)
          .toSet();
      await tester.runAsync(() async {
        await Future.wait(
          providers.map((provider) {
            return precacheImage(
              provider,
              context,
              onError: (error, stack) => imageErrors.add(error),
            );
          }),
        ).timeout(const Duration(seconds: 10));
      });
      expect(imageErrors, isEmpty);
      await tester.pump(const Duration(milliseconds: 250));
      stage('assertions');
      expect(find.byKey(const Key('match_canvas')), findsOneWidget);
      expect(find.byKey(const Key('board_artwork')), findsOneWidget);
      expect(find.byKey(const Key('profile_orange')), findsOneWidget);
      expect(find.byKey(const Key('profile_green')), findsOneWidget);
      expect(find.byKey(const Key('profile_blue')), findsOneWidget);
      expect(find.byKey(const Key('profile_magenta')), findsOneWidget);
      for (final color in const ['orange', 'green', 'magenta', 'blue']) {
        final avatar = find.byKey(Key('profile_avatar_$color'));
        final name = find.byKey(Key('profile_name_$color'));
        expect(avatar, findsOneWidget);
        expect(name, findsOneWidget);
        final square = tester.getRect(avatar).size;
        expect(square.width, closeTo(square.height, .01));
        expect(square.width, greaterThanOrEqualTo(32));
        expect(tester.getRect(name).height, greaterThanOrEqualTo(12));
        expect(
          tester.getRect(name).bottom,
          lessThanOrEqualTo(tester.getRect(avatar).top),
        );
      }
      expect(find.byKey(const Key('chat_button')), findsOneWidget);
      expect(find.byKey(const Key('quick_reactions_button')), findsOneWidget);
      expect(find.byKey(const Key('turn_status')), findsOneWidget);
      expect(find.byKey(const Key('exit_match')), findsOneWidget);
      expect(find.byKey(const Key('more_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final key in const [
        Key('chat_button'),
        Key('quick_reactions_button'),
        Key('more_button'),
        Key('exit_match'),
        Key('roll_dice'),
      ]) {
        final target = tester.getRect(find.byKey(key)).size;
        expect(target.width, greaterThanOrEqualTo(48));
        expect(target.height, greaterThanOrEqualTo(48));
      }

      final canvas = tester.getRect(find.byKey(const Key('board_stage')));
      expect(canvas.width, closeTo(canvas.height, .01));
      expect(canvas.width, lessThanOrEqualTo(viewport.width + .01));
      expect(canvas.height, lessThanOrEqualTo(viewport.height + .01));
      expect(canvas.left, greaterThanOrEqualTo(-.01));
      expect(canvas.top, greaterThanOrEqualTo(top - .01));
      expect(canvas.bottom, lessThanOrEqualTo(viewport.height - bottom + .01));
      final board = tester.getRect(find.byKey(const Key('board_artwork')));
      expect(board.left, greaterThanOrEqualTo(-.01));
      expect(board.right, lessThanOrEqualTo(viewport.width + .01));
      expect(board.top, greaterThanOrEqualTo(-.01));
      expect(board.bottom, lessThanOrEqualTo(viewport.height + .01));
      expect(board.left, greaterThanOrEqualTo(canvas.left - .01));
      expect(board.right, lessThanOrEqualTo(canvas.right + .01));
      expect(board.top, greaterThanOrEqualTo(canvas.top - .01));
      expect(board.bottom, lessThanOrEqualTo(canvas.bottom + .01));
      for (final key in [
        'roll_dice',
        'chat_button',
        'quick_reactions_button',
        'more_button',
      ]) {
        expect(
          tester.getRect(find.byKey(Key(key))).top,
          greaterThanOrEqualTo(canvas.bottom - .01),
        );
      }
      final profileCenters = ['orange', 'green', 'magenta', 'blue']
          .map((color) => tester.getCenter(find.byKey(Key('profile_$color'))))
          .toList();
      for (var i = 1; i < profileCenters.length; i++) {
        expect(profileCenters[i].dx, greaterThan(profileCenters[i - 1].dx));
        expect(profileCenters[i].dy, closeTo(profileCenters[0].dy, .01));
      }

      for (final color in const ['orange', 'green', 'magenta', 'blue']) {
        expect(
          tester.getRect(find.byKey(Key('profile_$color'))).overlaps(board),
          isFalse,
        );
      }
      expect(find.text('Roll dice'), findsOneWidget);

      // Engine/image callbacks and filesystem operations must run outside
      // the widget binding's fake-async zone. Keeping only writes in runAsync
      // can leave image completion callbacks pending during test teardown.
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('match_screen_capture')),
      );
      await tester.runAsync(() async {
        stage('capture');
        final image = await boundary
            .toImage(pixelRatio: 1)
            .timeout(const Duration(seconds: 10));
        try {
          expect(image.width, viewport.width.toInt());
          expect(image.height, viewport.height.toInt());
          stage('encode');
          final bytes = await image
              .toByteData(format: ui.ImageByteFormat.png)
              .timeout(const Duration(seconds: 10));
          expect(bytes, isNotNull);
          final output = File(
            'test-artifacts/acceptance/${extended ? 'extended-' : ''}match-screen-'
            '${viewport.width.toInt()}x${viewport.height.toInt()}.png',
          );
          stage('create directory');
          await output.parent
              .create(recursive: true)
              .timeout(const Duration(seconds: 10));
          stage('write PNG');
          await output
              .writeAsBytes(
                bytes!.buffer
                    .asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
                flush: true,
              )
              .timeout(const Duration(seconds: 10));
          stage('verify PNG');
          final encoded =
              await output.readAsBytes().timeout(const Duration(seconds: 10));
          final codec = await ui
              .instantiateImageCodec(encoded)
              .timeout(const Duration(seconds: 10));
          try {
            final frame =
                await codec.getNextFrame().timeout(const Duration(seconds: 10));
            try {
              expect(frame.image.width, viewport.width.toInt());
              expect(frame.image.height, viewport.height.toInt());
            } finally {
              frame.image.dispose();
            }
          } finally {
            codec.dispose();
          }
        } finally {
          image.dispose();
        }
        stage('capture complete');
      });
      // Drain post-frame image listeners before disposing the match.
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
