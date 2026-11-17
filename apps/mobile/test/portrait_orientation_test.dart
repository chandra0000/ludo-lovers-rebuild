import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/portrait_orientation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('launch requests only portraitUp from the platform', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await configurePortraitOrientation();
    final request = calls.single;
    expect(request.method, 'SystemChrome.setPreferredOrientations');
    expect(request.arguments, ['DeviceOrientation.portraitUp']);
  });
}
