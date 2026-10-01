import '../models/dialogue.dart';

final coffeeNycScenario = DialogueScenario(
  id: 'coffee-nyc',
  title: 'Café em Manhattan • Conversação Livre',
  partnerName: 'Emma',
  partnerBadge: 'Nativo US',
  avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
  initialMessage: const ChatMessage(
    id: 'm1',
    sender: 'ai',
    text:
        "Hi there! Welcome to The Daily Roast coffee shop in Manhattan. What can I get started for you today?",
    timestamp: 'Agora',
    suggestion:
        'Tente pedir: "Hi, could I please get an iced oat milk latte?" ou "Could I have a black coffee and a croissant?"',
  ),
  rules: const [
    DialogueRule(
      id: 'drinks',
      keywords: [
        'latte',
        'cappuccino',
        'espresso',
        'iced coffee',
        'americano',
        'macchiato',
        'mocha',
        'cold brew',
        'frappuccino',
        'flat white',
        'tea',
        'matcha',
        'coffee',
      ],
      reply:
          'Great choice! What size would you like — small, medium, or large? And would you prefer whole milk, oat milk, or almond milk?',
      suggestion: 'Dica para tamanho e leite: "A medium with oat milk, please."',
    ),
    DialogueRule(
      id: 'food',
      keywords: [
        'croissant',
        'bagel',
        'muffin',
        'pastry',
        'cookie',
        'sandwich',
        'brownie',
        'donut',
        'scone',
        'cake',
        'bread',
        'snack',
      ],
      reply:
          'Delicious! We bake those fresh every morning. Would you like me to warm that up for you?',
      suggestion:
          'Dica para responder: "Yes, please warm it up." ou "No, that is fine as is, thanks."',
    ),
    DialogueRule(
      id: 'customizations',
      keywords: [
        'oat',
        'almond',
        'skim',
        'soy',
        'whole',
        'vanilla',
        'caramel',
        'sugar',
        'syrup',
        'sweet',
        'decaf',
        'extra shot',
        'ice',
        'iced',
        'hot',
        'warm',
      ],
      reply:
          'Got it, custom order noted! Would you like room for cream, or are you good to go?',
      suggestion:
          'Dica de vocabulário: "Room for cream" significa deixar um espaço no topo do copo para leite ou creme.',
    ),
    DialogueRule(
      id: 'sizes',
      keywords: [
        'small',
        'medium',
        'large',
        'regular',
        'venti',
        'tall',
        'grande',
        '12oz',
        '16oz',
        '20oz',
      ],
      reply:
          'Perfect size! That comes out to \$4.75. Will you be paying with cash, credit card, or Apple Pay?',
      suggestion:
          'Dica de pagamento: "I will pay with card, please" ou "Apple Pay, please."',
    ),
    DialogueRule(
      id: 'payment',
      keywords: [
        'card',
        'credit',
        'debit',
        'cash',
        'apple pay',
        'pay',
        'receipt',
        'dollar',
        'dollars',
        'cents',
      ],
      reply:
          'All set, payment received! Your receipt is in the bag. We will call your name at the pick-up counter. Have a wonderful day in Manhattan!',
      suggestion:
          'Dica de polidez para encerrar: "Thank you so much! Have a great day!"',
    ),
    DialogueRule(
      id: 'goodbye',
      keywords: [
        'thank',
        'thanks',
        'bye',
        'goodbye',
        'have a good',
        'have a nice',
        'see you',
        'take care',
      ],
      reply:
          "You're very welcome! Thanks for stopping by The Daily Roast. See you next time!",
      suggestion: 'Dica de despedida: "Thank you, take care!"',
    ),
  ],
  defaultRule: const DialogueRule(
    id: 'default',
    keywords: [],
    reply:
        'Sure thing! Would you like anything else to go with that, or are you ready for the total?',
    suggestion:
        'Dica: Você pode pedir um café, um item de confeitaria ("a croissant"), ou dizer "That will be all, thank you!".',
  ),
);
