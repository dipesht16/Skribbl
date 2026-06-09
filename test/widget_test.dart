import 'package:flutter_test/flutter_test.dart';
import 'package:skribble_io/main.dart';
import 'package:skribble_io/services/game_state_controller.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final controller = GameStateController();
    await tester.pumpWidget(MyApp(controller: controller));

    // Verify that our app renders successfully
    expect(find.byType(MyApp), findsOneWidget);
  });
}
