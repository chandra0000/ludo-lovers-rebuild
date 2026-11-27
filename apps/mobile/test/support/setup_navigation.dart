import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reveal a lazily built start card after the name editor changes list extent.
/// Shared by widget regression and installed Android/iOS navigation checks.
Future<void> revealLocalMatchStart(WidgetTester tester) async {
  final scroll = find.byType(Scrollable).first;
  tester.state<ScrollableState>(scroll).position.jumpTo(0);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('start_local_match')),
    180,
    scrollable: scroll,
  );
  await tester.pumpAndSettle();
}
