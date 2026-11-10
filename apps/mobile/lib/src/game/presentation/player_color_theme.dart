import 'package:flutter/material.dart';

import '../domain/player_color.dart';

extension PlayerColorTheme on PlayerColor {
  Color get color => switch (this) {
        PlayerColor.orange => const Color(0xFFFF8928),
        PlayerColor.green => const Color(0xFF33FF28),
        PlayerColor.magenta => const Color(0xFFF428FF),
        PlayerColor.blue => const Color(0xFF289EFF),
      };
}
