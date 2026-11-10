import 'package:cloud_courier/courier_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unconfigured app shows its announcement and setup prompt', (
    tester,
  ) async {
    await tester.pumpWidget(const CourierApp());
    await tester.pumpAndSettle();

    expect(find.text('Cloud Courier'), findsOneWidget);
    expect(find.text('Ready for campus updates'), findsOneWidget);
    expect(find.text('Firebase setup required.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
