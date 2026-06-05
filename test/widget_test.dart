import 'package:flutter_test/flutter_test.dart';

import 'package:demo/main.dart';

void main() {
  testWidgets('App launches and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AirHockeyApp());
    expect(find.text('🏒 Air Hockey'), findsOneWidget);
    expect(find.text('建立房間'), findsOneWidget);
    expect(find.text('加入房間'), findsOneWidget);
  });
}
