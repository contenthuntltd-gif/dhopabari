import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/main.dart';

void main() {
  testWidgets('App launches to the admin login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DhopaBariAdminApp());
    await tester.pump();

    expect(find.text('সাইন ইন করুন'), findsOneWidget);
    expect(find.text('ধোপা বাড়ি অ্যাডমিন'), findsOneWidget);
  });
}
