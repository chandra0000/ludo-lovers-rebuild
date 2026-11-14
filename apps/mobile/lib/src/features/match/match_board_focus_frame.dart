import 'package:flutter/material.dart';

/// Decorative boundary around the existing board crop.
///
/// Coordinates are in the fixed 576x1024 match canvas. This frame never
/// participates in hit testing and does not alter board or pawn geometry.
class MatchBoardFocusFrame extends StatelessWidget {
  const MatchBoardFocusFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 7,
      top: 195,
      width: 562,
      height: 562,
      child: IgnorePointer(
        child: DecoratedBox(
          key: Key('match_board_focus_frame'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(9)),
            border: Border.fromBorderSide(
              BorderSide(color: Color(0x99FFD36B), width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x442B9DFF),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
