import 'package:flutter/material.dart';

enum PlayerColor {
  orange(Color(0xFFFF8928), 0),
  green(Color(0xFF33FF28), 13),
  magenta(Color(0xFFF428FF), 26),
  blue(Color(0xFF289EFF), 39);

  const PlayerColor(this.value, this.entryIndex);

  final Color value;
  final int entryIndex;

  static const turnOrder = <PlayerColor>[
    PlayerColor.orange,
    PlayerColor.green,
    PlayerColor.magenta,
    PlayerColor.blue,
  ];

  PlayerColor get next =>
      turnOrder[(turnOrder.indexOf(this) + 1) % turnOrder.length];
}
