import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta/pages/shell/app_shell.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows the text tabs and the content, and reports a tap', (tester) async {
    final selected = <AppTab>[];

    await tester.pumpApp(
      AppShell(current: AppTab.clients, onSelect: selected.add, child: const Text('content')),
    );
    await tester.tap(find.text('Terminy'));

    expect(find.text('content'), findsOneWidget);
    expect(find.text('Klienci'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(selected, [AppTab.due]);
    // The bar takes its own height, not the screen's.
    final tab = find.ancestor(of: find.text('Terminy'), matching: find.byType(InkWell));
    expect(tester.getSize(tab).height, 56);
  });

  testWidgets('marks the current tab selected for screen readers', (tester) async {
    await tester.pumpApp(
      AppShell(current: AppTab.due, onSelect: (_) {}, child: const SizedBox()),
    );

    expect(
      tester.getSemantics(find.text('Terminy')),
      isSemantics(isSelected: true, isButton: true, label: 'Terminy'),
    );
  });
}
