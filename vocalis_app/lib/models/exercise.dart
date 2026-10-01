enum Difficulty {
  basico('Básico'),
  intermediario('Intermediário'),
  avancado('Avançado');

  final String label;
  const Difficulty(this.label);

  static Difficulty fromString(String val) {
    switch (val.toLowerCase()) {
      case 'básico':
      case 'basico':
        return Difficulty.basico;
      case 'intermediário':
      case 'intermediario':
        return Difficulty.intermediario;
      case 'avançado':
      case 'avancado':
        return Difficulty.avancado;
      default:
        return Difficulty.basico;
    }
  }
}

class Exercise {
  final String id;
  final String sentence;
  final String phoneticIpa;
  final String translation;
  final String friendlyPhonetic;
  final Difficulty difficulty;
  final String category;
  final List<String> keyPhonemes;
  final String tip;
  final String accent;

  const Exercise({
    required this.id,
    required this.sentence,
    required this.phoneticIpa,
    this.translation = '',
    this.friendlyPhonetic = '',
    required this.difficulty,
    required this.category,
    required this.keyPhonemes,
    required this.tip,
    this.accent = 'US',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sentence': sentence,
    'phoneticIpa': phoneticIpa,
    'translation': translation,
    'friendlyPhonetic': friendlyPhonetic,
    'difficulty': difficulty.label,
    'category': category,
    'keyPhonemes': keyPhonemes,
    'tip': tip,
    'accent': accent,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      sentence: json['sentence'] as String,
      phoneticIpa: json['phoneticIpa'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      friendlyPhonetic: json['friendlyPhonetic'] as String? ?? '',
      difficulty: Difficulty.fromString(json['difficulty'] as String? ?? 'Básico'),
      category: json['category'] as String? ?? 'Geral',
      keyPhonemes: (json['keyPhonemes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tip: json['tip'] as String? ?? '',
      accent: json['accent'] as String? ?? 'US',
    );
  }
}
