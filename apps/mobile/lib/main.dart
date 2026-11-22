import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/startup_frame_gate.dart';
import 'src/portrait_orientation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurePortraitOrientation();
  final firstFrame = StartupFrameGate(WidgetsBinding.instance);
  runApp(LudoLoversApp(onFirstViewReady: firstFrame.release));
}
