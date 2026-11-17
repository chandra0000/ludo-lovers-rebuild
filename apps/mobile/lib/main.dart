import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/portrait_orientation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurePortraitOrientation();
  runApp(const LudoLoversApp());
}
