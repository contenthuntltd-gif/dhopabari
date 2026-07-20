import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/main.dart';
import 'package:customer_app/widgets/app_logo.dart';

void main() {
  testWidgets('App launches to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DhopaBariApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('স্বাগতম!'), findsOneWidget);
    expect(find.byType(AppLogo), findsWidgets);
  });
}
