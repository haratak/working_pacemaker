import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpWidgetAndSettle(Widget widget, WidgetTester tester) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

abstract class Screen {
  @protected
  Finder key(String keyValue) => find.byKey(Key(keyValue));
  Finder text(String text) => find.text(text);
}
