import 'package:flutter_test/flutter_test.dart';
import 'package:eco_weather/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame using our new class name
    await tester.pumpWidget(const EcoWeatherApp());

    // Verify that our placeholder text is on the screen
    expect(find.text('Eco Weather'), findsWidgets);
    expect(find.text('Weather data will appear here'), findsOneWidget);
  });
}