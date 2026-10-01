enum WordStatus {
  mastered,
  near,
  needsWork;

  static WordStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'mastered':
        return WordStatus.mastered;
      case 'near':
        return WordStatus.near;
      case 'needs_work':
      case 'needswork':
      default:
        return WordStatus.needsWork;
    }
  }

  String get label {
    switch (this) {
      case WordStatus.mastered:
        return 'Correto';
      case WordStatus.near:
        return 'Quase';
      case WordStatus.needsWork:
        return 'Precisa treinar';
    }
  }
}

class PhonemeEvaluation {
  final String phoneme;
  final double score;
  final WordStatus status;
  final String? tip;

  const PhonemeEvaluation({
    required this.phoneme,
    required this.score,
    required this.status,
    this.tip,
  });

  factory PhonemeEvaluation.fromJson(Map<String, dynamic> json) {
    return PhonemeEvaluation(
      phoneme: json['phoneme'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      status: WordStatus.fromString(json['status'] as String? ?? 'needs_work'),
      tip: json['tip'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'phoneme': phoneme,
    'score': score,
    'status': status.name,
    'tip': tip,
  };
}

class WordEvaluation {
  final String word;
  final String spokenWord;
  final WordStatus status;
  final String ipa;
  final String? tip;
  final double score;
  final List<PhonemeEvaluation> phonemes;

  const WordEvaluation({
    required this.word,
    required this.spokenWord,
    required this.status,
    required this.ipa,
    this.tip,
    required this.score,
    this.phonemes = const [],
  });

  factory WordEvaluation.fromJson(Map<String, dynamic> json) {
    return WordEvaluation(
      word: json['word'] as String? ?? '',
      spokenWord: json['spokenWord'] as String? ?? (json['spoken_word'] as String? ?? ''),
      status: WordStatus.fromString(json['status'] as String? ?? 'needs_work'),
      ipa: json['ipa'] as String? ?? '',
      tip: json['tip'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      phonemes: (json['phonemes'] as List<dynamic>?)
              ?.map((p) => PhonemeEvaluation.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'spokenWord': spokenWord,
    'status': status.name,
    'ipa': ipa,
    'tip': tip,
    'score': score,
    'phonemes': phonemes.map((p) => p.toJson()).toList(),
  };
}

class PronunciationResult {
  final double overallScore;
  final double fluencyScore;
  final double accuracyScore;
  final double completenessScore;
  final String transcript;
  final String targetSentence;
  final List<WordEvaluation> words;
  final String feedbackSummary;
  final String? articulationTip;
  final String provider;

  const PronunciationResult({
    required this.overallScore,
    required this.fluencyScore,
    required this.accuracyScore,
    required this.completenessScore,
    required this.transcript,
    required this.targetSentence,
    required this.words,
    required this.feedbackSummary,
    this.articulationTip,
    this.provider = 'backend',
  });

  factory PronunciationResult.fromJson(Map<String, dynamic> json) {
    return PronunciationResult(
      overallScore: (json['overallScore'] as num? ?? json['overall_score'] as num? ?? 0).toDouble(),
      fluencyScore: (json['fluencyScore'] as num? ?? json['fluency_score'] as num? ?? 0).toDouble(),
      accuracyScore: (json['accuracyScore'] as num? ?? json['accuracy_score'] as num? ?? 0).toDouble(),
      completenessScore:
          (json['completenessScore'] as num? ?? json['completeness_score'] as num? ?? 0).toDouble(),
      transcript: json['transcript'] as String? ?? '',
      targetSentence: json['targetSentence'] as String? ?? (json['target_sentence'] as String? ?? ''),
      words: (json['words'] as List<dynamic>?)
              ?.map((w) => WordEvaluation.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      feedbackSummary: json['feedbackSummary'] as String? ?? (json['feedback_summary'] as String? ?? ''),
      articulationTip: json['articulationTip'] as String? ?? (json['articulation_tip'] as String?),
      provider: json['provider'] as String? ?? 'backend',
    );
  }

  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'fluencyScore': fluencyScore,
    'accuracyScore': accuracyScore,
    'completenessScore': completenessScore,
    'transcript': transcript,
    'targetSentence': targetSentence,
    'words': words.map((w) => w.toJson()).toList(),
    'feedbackSummary': feedbackSummary,
    'articulationTip': articulationTip,
    'provider': provider,
  };
}
