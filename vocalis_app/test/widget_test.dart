import 'package:flutter/material.dart' show Icons, TextField;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vocalis_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders home screen with practice actions', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const VocalisApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Vocalis AI'), findsOneWidget);
    expect(find.text('Digitar Frase'), findsOneWidget);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Café em Manhattan'), findsOneWidget);
    expect(find.text('Revisão de Dificuldades'), findsOneWidget);
    expect(find.text('Frases para Praticar'), findsOneWidget);

    // Catalog filter chips
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Básico (5)'), findsOneWidget);
    expect(find.text('Intermediário (10)'), findsOneWidget);
    expect(find.text('Avançado (5)'), findsOneWidget);

    // Tap Avançado filter and verify filtered list count
    await tester.tap(find.text('Avançado (5)'));
    await tester.pump();
    expect(find.text('5 frases'), findsOneWidget);
  });

  testWidgets('Practice screen exposes mic recording and handles missing microphone',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The record plugin has no platform implementation under the test
    // binding; answering its channel keeps the flow deterministic.
    final recordChannel = const MethodChannel('com.llfbandit.record/messages');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      recordChannel,
      (call) async {
        if (call.method == 'hasPermission') return false;
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, null));

    await tester.pumpWidget(const VocalisApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Digitar Frase'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pressione para Falar'), findsOneWidget);
    expect(find.text('Comparar e Avaliar'), findsOneWidget);
    expect(find.text('O que você pronunciou (ou deixe vazio para testar)'),
        findsOneWidget);
    expect(find.text('US 🇺🇸'), findsOneWidget);

    // Toggle to UK accent
    await tester.tap(find.text('US 🇺🇸'));
    await tester.pump();
    expect(find.text('UK 🇬🇧'), findsOneWidget);

    // No microphone permission/channel in the test environment:
    // tapping the mic button must show a friendly error instead of crashing.
    await tester.tap(find.text('Pressione para Falar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Não foi possível acessar o microfone'),
      findsOneWidget,
    );
    expect(find.text('Pressione para Falar'), findsOneWidget);
  });

  testWidgets('Free speaking screen renders dialogue and responds to user input',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const VocalisApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Café em Manhattan'), findsOneWidget);
    await tester.tap(find.text('Café em Manhattan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Emma'), findsOneWidget);
    expect(find.text('Nativo US'), findsOneWidget);
    expect(find.textContaining('Welcome to The Daily Roast'), findsOneWidget);

    // Type a beverage order
    await tester.enterText(
      find.byType(TextField),
      'Can I get an iced latte with oat milk, please?',
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    // Advance timers for the realistic AI response delay (600ms)
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Can I get an iced latte with oat milk, please?'),
        findsOneWidget);
    expect(find.textContaining('small, medium, or large'), findsOneWidget);
    expect(find.text('Ouvir resposta'), findsAtLeastNWidgets(1));
  });
}
