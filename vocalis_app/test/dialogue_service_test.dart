import 'package:flutter_test/flutter_test.dart';
import 'package:vocalis_app/data/dialogue_scenarios.dart';
import 'package:vocalis_app/models/dialogue.dart';

void main() {
  group('Dialogue Matching Engine - Café em Manhattan', () {
    test('identifica pedido de bebida e sugere tamanho/leite', () {
      final res = matchDialogueResponse(
        'Could I please get an iced oat milk latte?',
        coffeeNycScenario,
      );

      expect(res.matchedRuleId, 'drinks');
      expect(res.text, contains('small, medium, or large'));
      expect(res.suggestion, contains('oat milk'));
    });

    test('identifica pedido de comida e pergunta se aquece', () {
      final res = matchDialogueResponse(
        'I would like a warm chocolate croissant, please.',
        coffeeNycScenario,
      );

      expect(res.matchedRuleId, 'food');
      expect(res.text, contains('warm that up for you'));
      expect(res.suggestion, contains('warm it up'));
    });

    test('identifica tamanho e pergunta sobre forma de pagamento', () {
      final res = matchDialogueResponse(
        'Make that a large, please.',
        coffeeNycScenario,
      );

      expect(res.matchedRuleId, 'sizes');
      expect(res.text, contains('4.75'));
      expect(res.suggestion, contains('card'));
    });

    test('identifica pagamento e finaliza pedido', () {
      final res = matchDialogueResponse(
        'I will pay with Apple Pay.',
        coffeeNycScenario,
      );

      expect(res.matchedRuleId, 'payment');
      expect(res.text, contains('payment received'));
      expect(res.suggestion, contains('Thank you so much'));
    });

    test('identifica agradecimento/despedida', () {
      final res = matchDialogueResponse(
        'Thank you very much, take care!',
        coffeeNycScenario,
      );

      expect(res.matchedRuleId, 'goodbye');
      expect(res.text, contains("You're very welcome"));
    });

    test('usa regra padrão quando a fala é livre e não tem palavra-chave exata',
        () {
      final res = matchDialogueResponse(
        'What time do you guys close tonight?',
        coffeeNycScenario,
      );

      expect(res.matchedRuleId, isNull);
      expect(
        res.text,
        contains('Would you like anything else to go with that'),
      );
    });
  });
}
