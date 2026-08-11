import 'package:chorebuddy/features/chores/presentation/widgets/search_and_sort_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget() {
    return const ProviderScope(
      child: MaterialApp(home: Scaffold(body: SearchAndSortBar())),
    );
  }

  testWidgets(
    'header row extent is the same collapsed and with search expanded',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final collapsedHeight = tester
          .getSize(find.byType(SearchAndSortBar))
          .height;

      await tester.tap(find.byKey(const Key('search_icon_button')));
      await tester.pumpAndSettle();

      // Confirms search actually expanded (the field, not the icon, is on
      // screen), so the height comparison below is meaningful.
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.byKey(const Key('search_icon_button')), findsNothing);

      final expandedHeight = tester
          .getSize(find.byType(SearchAndSortBar))
          .height;

      expect(expandedHeight, equals(collapsedHeight));
    },
  );
}
