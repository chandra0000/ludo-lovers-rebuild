enum PlayerColor {
  orange(0),
  green(13),
  magenta(26),
  blue(39);

  const PlayerColor(this.entryIndex);

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
