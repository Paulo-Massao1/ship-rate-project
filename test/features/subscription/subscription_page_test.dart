import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ship_rate/features/subscription/subscription_page.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

void main() {
  testWidgets('explains restore purchases before contacting the store', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SubscriptionPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restaurar compras'));
    await tester.pumpAndSettle();

    expect(find.text('Restaurar compras?'), findsOneWidget);
    expect(
      find.textContaining('Nenhuma nova cobrança será realizada'),
      findsOneWidget,
    );
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Restaurar'), findsOneWidget);
  });
}
