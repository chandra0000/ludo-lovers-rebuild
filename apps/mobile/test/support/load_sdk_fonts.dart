import 'dart:io';

import 'package:flutter/services.dart';

/// Use the pinned SDK's Android fonts rather than Ahem blocks in acceptance PNGs.
/// This changes only test rendering; it does not add or replace app assets.
Future<void> loadSdkFonts() async {
  for (final entry in {
    'Nunito': [400, 600, 700, 800],
    'Cinzel': [700],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final weight in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/${entry.key}-$weight.ttf'));
    }
    await loader.load();
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final fontDirectory = '$flutterRoot/bin/cache/artifacts/material_fonts';
  for (final entry in {
    'Roboto': [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Black.ttf',
    ],
    'MaterialIcons': ['MaterialIcons-Regular.otf'],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final name in entry.value) {
      loader.addFont(
        File('$fontDirectory/$name').readAsBytes().then(
              (bytes) => bytes.buffer.asByteData(
                bytes.offsetInBytes,
                bytes.lengthInBytes,
              ),
            ),
      );
    }
    await loader.load();
  }
  // Use the installed OS emoji face for real software-rendered social captures.
  // No runtime asset is added or replaced; native captures use platform fonts.
  final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
  if (await emoji.exists()) {
    final loader = FontLoader('Noto Color Emoji');
    loader.addFont(
      emoji.readAsBytes().then(
            (bytes) => bytes.buffer
                .asByteData(bytes.offsetInBytes, bytes.lengthInBytes),
          ),
    );
    await loader.load();
  }
}
