import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import 'match_assets.dart';
import 'royal_crown.dart';

/// Prepares the exact images rendered by the match, retaining decoded frames
/// while the route is alive. No game state or rules live here.
class MatchScenePreparation extends StatefulWidget {
  const MatchScenePreparation({
    super.key,
    required this.child,
    required this.onReadinessChanged,
    required this.onExit,
    this.board = MatchAssets.board,
    this.logo = MatchAssets.logo,
  });
  final Widget child;
  final ImageProvider board, logo;
  final ValueChanged<bool> onReadinessChanged;
  final VoidCallback onExit;

  @override
  State<MatchScenePreparation> createState() => _MatchScenePreparationState();
}

class _MatchScenePreparationState extends State<MatchScenePreparation> {
  final _streams = <(ImageStream, ImageStreamListener)>[];
  final _decoded = <int>{};
  final _failed = <int>{};
  Timer? _deadline;
  bool _subscribed = false;
  bool _subscribing = false;
  bool _retrying = false;
  bool? _reported;
  Object? _error;
  int _generation = 0;
  int _attempt = 0;
  bool get _ready => _decoded.length == 2 && _error == null && !_retrying;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) _subscribe();
  }

  @override
  void didUpdateWidget(MatchScenePreparation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.board != widget.board || oldWidget.logo != widget.logo) {
      _attempt++;
      _subscribe();
    }
  }

  void _detach() {
    _deadline?.cancel();
    for (final (stream, listener) in _streams) {
      stream.removeListener(listener);
    }
    _streams.clear();
  }

  void _notify() {
    final ready = _ready;
    if (ready == _reported) return;
    _reported = ready;
    widget.onReadinessChanged(ready);
    if (ready) _deadline?.cancel();
  }

  void _subscribe() {
    _detach();
    _subscribed = true;
    final generation = ++_generation;
    _decoded.clear();
    _failed.clear();
    _error = null;
    _retrying = false;
    _notify();
    _deadline = Timer(const Duration(seconds: 12), () {
      if (!mounted || generation != _generation || _ready) return;
      setState(() => _error = TimeoutException('Match image preparation'));
      _notify();
    });
    final providers = [widget.board, widget.logo];
    _subscribing = true;
    for (var index = 0; index < providers.length; index++) {
      final stream =
          providers[index].resolve(createLocalImageConfiguration(context));
      final listener = ImageStreamListener(
        (info, synchronous) {
          info.dispose();
          if (!mounted || generation != _generation) return;
          _decoded.add(index);
          if (!_subscribing) setState(() {});
          _notify();
        },
        onError: (Object error, StackTrace? trace) {
          if (!mounted || generation != _generation) return;
          _failed.add(index);
          _error = error;
          _deadline?.cancel();
          if (!_subscribing) setState(() {});
          _notify();
        },
      );
      _streams.add((stream, listener));
      stream.addListener(listener);
    }
    _subscribing = false;
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    final generation = ++_generation;
    _detach();
    _notify();
    final providers = [widget.board, widget.logo];
    try {
      for (var index = 0; index < providers.length; index++) {
        if (_failed.contains(index) || !_decoded.contains(index)) {
          await providers[index].evict().timeout(const Duration(seconds: 3));
        }
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _attempt++;
        _subscribe();
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _retrying = false;
      });
    }
  }

  @override
  void dispose() {
    _generation++;
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          TickerMode(
            enabled: _ready,
            child: ExcludeFocus(
              excluding: !_ready,
              child: IgnorePointer(
                ignoring: !_ready,
                child: ExcludeSemantics(
                  excluding: !_ready,
                  child: Opacity(
                    key: const Key('prepared_match_scene'),
                    opacity: _ready ? 1 : 0,
                    child: KeyedSubtree(
                      key: ValueKey(_attempt),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!_ready)
            Column(
              key: const Key('match_preparation_view'),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    key: const Key('preparation_exit'),
                    tooltip: 'Exit match preparation',
                    constraints:
                        const BoxConstraints.tightFor(width: 48, height: 48),
                    onPressed: widget.onExit,
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xFFFFE3A0)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Semantics(
                          liveRegion: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_decoded.contains(1))
                                ClipOval(
                                  child: Image(
                                    image: widget.logo,
                                    width: 88,
                                    height: 88,
                                    semanticLabel: 'Ludo Lovers',
                                  ),
                                )
                              else
                                const RoyalCrown(size: 72),
                              const SizedBox(height: 24),
                              Text(
                                _error == null
                                    ? 'Preparing your match…'
                                    : 'Match images could not be prepared',
                                textAlign: TextAlign.center,
                                style:
                                    AppTypography.status.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 16),
                              if (_error == null)
                                LinearProgressIndicator(
                                  value: _decoded.length / 2,
                                  semanticsLabel: 'Match images ready',
                                  semanticsValue: '${_decoded.length} of 2',
                                  color: const Color(0xFFD9AD55),
                                  backgroundColor: const Color(0xFF21162D),
                                )
                              else ...[
                                const Text(
                                  'Retry keeps your current match. You can also go back.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body,
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  key: const Key('retry_match_preparation'),
                                  onPressed: _retrying ? null : _retry,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                  ),
                                  child: Text(
                                    _retrying
                                        ? 'Retrying…'
                                        : 'Retry preparation',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
}
