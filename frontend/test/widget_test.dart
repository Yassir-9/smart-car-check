import 'package:flutter_test/flutter_test.dart';

import 'package:car_ai_diagnosis/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CarAiApp());
    await tester.pump();

    expect(find.byType(CarAiApp), findsOneWidget);
  });
}
