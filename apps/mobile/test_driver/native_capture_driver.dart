import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

/// Host-side callback for actual installed-app PNGs; rejects empty/bad captures.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [arguments]) async {
      if (!RegExp(r'^native-[a-z0-9-]+$').hasMatch(name) || bytes.length < 24) {
        return false;
      }
      const signature = [137, 80, 78, 71, 13, 10, 26, 10];
      for (var i = 0; i < signature.length; i++) {
        if (bytes[i] != signature[i]) return false;
      }
      final file = File('test-artifacts/native/$name.png');
      await file.parent
          .create(recursive: true)
          .timeout(const Duration(seconds: 10));
      await file.writeAsBytes(bytes).timeout(const Duration(seconds: 10));
      return true;
    },
  );
}
