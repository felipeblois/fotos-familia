import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neviim/features/consent/consent_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ConsentScreen renderiza termo e botoes principais', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ConsentScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Uso familiar e privado'), findsOneWidget);
    expect(find.text('Coleta mínima de dados'), findsOneWidget);
    expect(find.text('Uso familiar'), findsOneWidget);
    expect(find.text('Concordo'), findsOneWidget);
    expect(find.text('Não aceito'), findsOneWidget);
  });
}
