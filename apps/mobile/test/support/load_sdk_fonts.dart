import 'dart:io';

import 'package:flutter/services.dart';

/// Use the pinned SDK's Android fonts rather than Ahem blocks in acceptance PNGs.
/// This changes only test rendering; it does not add or replace app assets.
Future<void> loadSdkFonts() async {
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
}
