import 'package:flutter/services.dart';

/// Request portrait on supported phones. Large-screen platform policy may
/// override app orientation; responsive rendering remains necessary.
Future<void> configurePortraitOrientation() =>
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
