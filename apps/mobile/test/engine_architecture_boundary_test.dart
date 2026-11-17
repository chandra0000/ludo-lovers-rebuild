import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('domain and session cannot depend on Flutter, plugins or presentation',
      () {
    final domain = Directory('lib/src/game/domain').absolute.uri;
    final application = Directory('lib/src/game/application').absolute.uri;
    final directives = RegExp(
      r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    for (final root in [domain, application]) {
      for (final file in Directory.fromUri(root)
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))) {
        for (final directive
            in directives.allMatches(file.readAsStringSync())) {
          final target = directive.group(1)!;
          if (target.startsWith('dart:') ||
              target == 'package:characters/characters.dart') {
            continue;
          }
          expect(
            target.startsWith('package:'),
            isFalse,
            reason: '${file.path} imports a platform/package dependency',
          );
          final resolved = file.absolute.uri.resolve(target).toString();
          expect(
            resolved.startsWith(domain.toString()) ||
                (root == application &&
                    resolved.startsWith(application.toString())),
            isTrue,
            reason: '${file.path} depends outside its engine layer: $target',
          );
        }
      }
    }
  });
}
