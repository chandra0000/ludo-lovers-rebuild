import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/splash/splash_screen.dart';
import 'package:ludo_lovers/src/startup_frame_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhaseRecordingBinding extends AutomatedTestWidgetsFlutterBinding {
  final releases = <SchedulerPhase>[];
  @override
  bool get firstFrameRasterized => false;
  @override
  void allowFirstFrame() {
    releases.add(schedulerPhase);
    super.allowFirstFrame();
  }
}

void main() {
  final binding = PhaseRecordingBinding();
  testWidgets(
      'startup replacement releases native frame only after render finalization',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final ready = Completer<bool>();
    final gate = StartupFrameGate(binding);
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          loadOnboarding: () => ready.future,
          onFirstViewReady: gate.release,
        ),
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Replacement ready'))),
    );
    ready.complete(true);
    await tester.pump();
    expect(binding.releases, hasLength(1));
    gate.release();
    await tester.pump();
    expect(binding.releases, hasLength(1));
    expect(
      binding.releases,
      isNot(contains(SchedulerPhase.persistentCallbacks)),
    );
    expect(find.text('Replacement ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final failure in [false, true]) {
    testWidgets(
        'bootstrap frame releases on ${failure ? "recoverable error" : "ready navigation"}',
        (tester) async {
      binding.releases.clear();
      SharedPreferences.setMockInitialValues({});
      final gate = StartupFrameGate(binding);
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            loadOnboarding: () async {
              if (failure) throw StateError('storage failed');
              return true;
            },
            onFirstViewReady: gate.release,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(binding.releases, [SchedulerPhase.postFrameCallbacks]);
      expect(
        find.byKey(Key(failure ? 'startup_retry' : 'open_game_setup')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(binding.releases, hasLength(1));
    });
  }
}
