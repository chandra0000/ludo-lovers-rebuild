import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_assets.dart';
import 'package:ludo_lovers/src/features/match/match_scene_preparation.dart';
import 'package:ludo_lovers/src/features/match/royal_game_header.dart';

class _ControlledImage extends ImageProvider<_ControlledImage> {
  final frames = [Completer<ImageInfo>(), Completer<ImageInfo>()];
  var loads = 0;
  Completer<bool>? eviction;
  @override
  Future<bool> evict({
    ImageCache? cache,
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) async {
    if (eviction != null) await eviction!.future;
    return super.evict(cache: cache, configuration: configuration);
  }

  @override
  Future<_ControlledImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    _ControlledImage key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(frames[loads++].future);

  Future<void> reveal(WidgetTester tester, {int attempt = 0}) async {
    final bitmap = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.orange, BlendMode.src);
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(1, 1);
      } finally {
        picture.dispose();
      }
    });
    frames[attempt].complete(ImageInfo(image: bitmap!));
    await tester.pump();
    await tester.pump();
  }
}

Widget _scene(
  _ControlledImage board,
  _ControlledImage logo, {
  ValueChanged<bool>? ready,
  VoidCallback? tap,
  VoidCallback? exit,
  FocusNode? focus,
}) =>
    MaterialApp(
      home: Scaffold(
        body: MatchScenePreparation(
          board: board,
          logo: logo,
          onReadinessChanged: ready ?? (_) {},
          onExit: exit ?? () {},
          child: Center(
            child: FilledButton(
              focusNode: focus,
              key: const Key('live_action'),
              onPressed: tap ?? () {},
              child: const Text('Live match'),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('hidden match controls cannot receive keyboard focus',
      (tester) async {
    final board = _ControlledImage(), logo = _ControlledImage();
    final focus = FocusNode();
    await tester.pumpWidget(_scene(board, logo, focus: focus));
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    await board.reveal(tester);
    await logo.reveal(tester);
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
  });
  testWidgets('retry finishing after disposal cannot reveal an old scene',
      (tester) async {
    final board = _ControlledImage(), logo = _ControlledImage();
    board.eviction = Completer<bool>();
    final states = <bool>[];
    await tester.pumpWidget(_scene(board, logo, ready: states.add));
    board.frames.first.completeError(StateError('Injected failure'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('retry_match_preparation')));
    await tester.pumpWidget(const SizedBox());
    board.eviction!.complete(true);
    await logo.reveal(tester);
    await tester.pump();
    expect(states, [false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late frames from replaced providers cannot reveal the new scene',
      (tester) async {
    final oldBoard = _ControlledImage(), oldLogo = _ControlledImage();
    final board = _ControlledImage(), logo = _ControlledImage();
    final states = <bool>[];
    await tester.pumpWidget(_scene(oldBoard, oldLogo, ready: states.add));
    await tester.pumpWidget(_scene(board, logo, ready: states.add));
    await oldBoard.reveal(tester);
    await oldLogo.reveal(tester);
    expect(states, [false]);
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('prepared_match_scene')))
          .opacity,
      0,
    );
    await board.reveal(tester);
    await logo.reveal(tester);
    expect(states, [false, true]);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'board alone cannot reveal partial HUD; board and logo reveal together',
      (tester) async {
    final board = _ControlledImage(), logo = _ControlledImage();
    final states = <bool>[];
    var taps = 0;
    await tester
        .pumpWidget(_scene(board, logo, ready: states.add, tap: () => taps++));
    await board.reveal(tester);
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('prepared_match_scene')))
          .opacity,
      0,
    );
    expect(find.byKey(const Key('live_action')).hitTestable(), findsNothing);
    expect(find.byKey(const Key('match_preparation_view')), findsOneWidget);
    await logo.reveal(tester);
    expect(states, [false, true]);
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('prepared_match_scene')))
          .opacity,
      1,
    );
    expect(find.byKey(const Key('match_preparation_view')), findsNothing);
    await tester.tap(find.byKey(const Key('live_action')));
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'failed board has one accessible retry and recovers without losing child',
      (tester) async {
    final board = _ControlledImage(), logo = _ControlledImage();
    await tester.pumpWidget(_scene(board, logo));
    await logo.reveal(tester);
    board.frames.first.completeError(StateError('Injected board decode error'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Match images could not be prepared'), findsOneWidget);
    final retry = find.byKey(const Key('retry_match_preparation'));
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    await tester.tap(retry);
    await tester.pump();
    await tester.pump();
    expect(board.loads, 2);
    await board.reveal(tester, attempt: 1);
    expect(find.byKey(const Key('match_preparation_view')), findsNothing);
    expect(logo.loads, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('stalled decode has bounded recovery and usable back navigation',
      (tester) async {
    final board = _ControlledImage(), logo = _ControlledImage();
    var exits = 0;
    await tester.pumpWidget(_scene(board, logo, exit: () => exits++));
    await tester.pump(const Duration(seconds: 12));
    expect(
      find.byKey(const Key('retry_match_preparation')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('preparation_exit')));
    expect(exits, 1);
    await tester.pumpWidget(const SizedBox());
    await board.reveal(tester);
    await logo.reveal(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'warm scene changes reuse decoded images without another loading reveal',
      (tester) async {
    final board = _ControlledImage(), logo = _ControlledImage();
    await tester.pumpWidget(_scene(board, logo));
    await board.reveal(tester);
    await logo.reveal(tester);
    await tester.pumpWidget(_scene(board, logo));
    expect(find.byKey(const Key('match_preparation_view')), findsNothing);
    expect(board.loads, 1);
    expect(logo.loads, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('live logo and preparation share the exact resized provider',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: RoyalBrandMark(size: 88))),
    );
    final image =
        tester.widget<Image>(find.byKey(const Key('match_brand_mark')));
    expect(image.image, same(MatchAssets.logo));
    expect((image.image as ResizeImage).width, 216);
    await tester.pumpWidget(const SizedBox());
  });
}
