import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/player_name.dart';

void main() {
  test('Unicode names normalize whitespace without rewriting identity text',
      () {
    expect(PlayerName.parse('  Zoë   王  '), 'Zoë 王');
    for (final name in [
      'علی',
      'लक्ष्मी',
      '山田太郎',
      'Éloïse',
      'Zoë 👨‍👩‍👧‍👦',
      'علی‌رضا',
    ]) {
      expect(PlayerName.errorFor(name), isNull);
    }
  });
  test('limit counts graphemes, including joined emoji and combining accents',
      () {
    expect(PlayerName.errorFor(List.filled(20, '👨‍👩‍👧‍👦').join()), isNull);
    expect(PlayerName.errorFor(List.filled(21, 'é').join()), isNotNull);
    expect(PlayerName.errorFor(List.filled(20, 'e\u0301').join()), isNull);
    expect(
      PlayerName.errorFor('A${List.filled(600, '\u0301').join()}'),
      isNotNull,
    );
  });
  test('blank, control, bidi-spoof and invisible-only input is rejected', () {
    for (final name in [
      '',
      '  ',
      '\u00a0',
      'A\nB',
      'A\tB',
      'A\u0000',
      '\u200b',
      'A\u202eB',
      'A\u2066B',
      '\u200d',
      '\ufe0f',
      '\u0301',
      '\u2800',
    ]) {
      expect(
        PlayerName.errorFor(name),
        isNotNull,
        reason: name.runes.toList().toString(),
      );
    }
  });
}
