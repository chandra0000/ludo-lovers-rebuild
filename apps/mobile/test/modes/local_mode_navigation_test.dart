import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/local_mode_navigation.dart';

void main() {
  testWidgets(
      'Public local 2/3 and preview modes start, roll, restart, exit and resume',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await verifyLocalModeNavigation(tester);
  });
}
