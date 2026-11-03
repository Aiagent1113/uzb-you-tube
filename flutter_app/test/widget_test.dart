import 'package:flutter_test/flutter_test.dart';
import 'package:uzdub_youtube_ai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UzDubApp(isSecurityPassed: true));
  });
}
