import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neviim/features/consent/consent_screen.dart';

void main() {
  testWidgets('ConsentScreen renderiza termo e botoes principais', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ConsentScreen(),
        ),
      ),
    );

    expect(find.text('Termo de Consentimento'), findsOneWidget);
    expect(find.text('Coleta minima de dados'), findsOneWidget);
    expect(find.text('Uso comunitario'), findsOneWidget);
    expect(find.text('Concordo'), findsOneWidget);
    expect(find.text('Nao aceito'), findsOneWidget);
  });
}
