// dart format off
// Temporary benchmark-only formatter exemption; remove after CI API validation.
import 'dart:math' as math;
import 'dart:ui' show FrameTiming;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../game/domain/board_geometry.dart';
import 'match_board_artwork.dart';

/// Opt-in rendering comparison. This is NOT a replacement for MatchScreen.
/// Both paths use the existing board crop and BoardGeometry; neither invokes
/// MatchSession or changes authoritative game state.
class RendererBenchmarkScreen extends StatefulWidget {
  const RendererBenchmarkScreen({super.key});

  @override
  State<RendererBenchmarkScreen> createState() =>
      _RendererBenchmarkScreenState();
}

class _RendererBenchmarkScreenState extends State<RendererBenchmarkScreen> {
  bool _useFlame = false;
  final List<double> _frameMs = <double>[];
  late final BenchmarkFlameGame _flameGame = BenchmarkFlameGame();

  void _onTimings(List<FrameTiming> timings) {
    if (!mounted) return;
    for (final timing in timings) {
      _frameMs.add(timing.totalSpan.inMicroseconds / 1000.0);
    }
    if (_frameMs.length > 600) {
      _frameMs.removeRange(0, _frameMs.length - 600);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  double get _p95 {
    if (_frameMs.isEmpty) return 0;
    final sorted = List<double>.of(_frameMs)..sort();
    return sorted[(sorted.length * 0.95).ceil() - 1];
  }

  String get _frameSummary {
    final p95 = _frameMs.isEmpty ? 'collecting' : '${_p95.toStringAsFixed(2)} ms';
    return 'Frames: ${_frameMs.length} | p95 total frame: $p95';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Renderer benchmark (experimental)')),
      body: Column(
        children: [
          SwitchListTile(
            title: Text(_useFlame ? 'Flame' : 'Flutter'),
            subtitle: const Text('Switch renderer; samples reset on change'),
            value: _useFlame,
            onChanged: (value) => setState(() {
              _useFlame = value;
              _frameMs.clear();
            }),
          ),
          Text(_frameSummary),
          const Text('Profile mode on a physical device required.'),
          const Text('Static scene only; no gameplay FPS claim.'),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = math.min(
                  constraints.maxWidth / BoardGeometry.canvasWidth,
                  constraints.maxHeight / BoardGeometry.canvasHeight,
                );
                return Center(
                  child: SizedBox(
                    width: BoardGeometry.canvasWidth * scale,
                    height: BoardGeometry.canvasHeight * scale,
                    child: _useFlame
                        ? GameWidget(game: _flameGame)
                        : const FittedBox(
                            fit: BoxFit.fill,
                            child: SizedBox(
                              width: BoardGeometry.canvasWidth,
                              height: BoardGeometry.canvasHeight,
                              child: Stack(
                                children: [
                                  MatchBoardArtwork(),
                                  BenchmarkAnchorOverlay(),
                                ],
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed positions exercise every shared track cell, without adding pawns
/// or changing MatchSession. Diagnostic markers are intentionally identical.
class BenchmarkAnchorOverlay extends StatelessWidget {
  const BenchmarkAnchorOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < BoardGeometry.trackLength; i++)
          Positioned(
            left: BoardGeometry.trackPosition(i).x *
                    BoardGeometry.canvasWidth -
                2,
            top: BoardGeometry.trackPosition(i).y *
                    BoardGeometry.canvasHeight -
                2,
            child: const SizedBox(
              width: 4,
              height: 4,
              child: ColoredBox(color: Colors.amber),
            ),
          ),
      ],
    );
  }
}

/// The Flame scene deliberately mirrors MatchBoardArtwork's existing
/// extracted board placement. It does not certify that crop against the
/// canonical 810x1440 source; visual acceptance remains a separate gate.
class BenchmarkFlameGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFF0C0A10);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(BoardGeometry.canvasWidth, BoardGeometry.canvasHeight),
    );
    final board = await images.load('board/extracted/board_exact.webp');
    await world.add(
      SpriteComponent(
        sprite: Sprite(board),
        position: Vector2(
          15 / 864 * BoardGeometry.canvasWidth,
          307 / 1536 * BoardGeometry.canvasHeight,
        ),
        size: Vector2(
          835 / 864 * BoardGeometry.canvasWidth,
          851 / 1536 * BoardGeometry.canvasHeight,
        ),
      ),
    );
    for (var i = 0; i < BoardGeometry.trackLength; i++) {
      final point = BoardGeometry.trackPosition(i);
      await world.add(
        RectangleComponent(
          position: Vector2(
            point.x * BoardGeometry.canvasWidth - 2,
            point.y * BoardGeometry.canvasHeight - 2,
          ),
          size: Vector2.all(4),
          paint: Paint()..color = Colors.amber,
        ),
      );
    }
  }
}
