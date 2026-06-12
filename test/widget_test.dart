import 'package:flutter_test/flutter_test.dart';

import 'package:opencrono/app.dart';

void main() {
  testWidgets('OpenCrono mostra la login iniziale',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OpenCronoApp());

    expect(find.text('OpenCrono'), findsOneWidget);
    expect(find.text('Accedi'), findsOneWidget);
  });
}
